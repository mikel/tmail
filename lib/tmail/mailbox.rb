#
# mailbox.rb
#
# Copyright (c) 1998-2004 Minero Aoki
#
# This program is free software.
# You can distribute/modify this program under the terms of
# the GNU Lesser General Public License version 2.1.
#

require 'tmail/compat'
require 'tmail/port'
require 'tmail/textutils'
require 'socket'
require 'mutex_m'

module TMail

  class MhMailbox

    PORT_CLASS = MhPort

    def initialize(dir)
      raise ArgumentError, "not directory: #{dir}" unless File.directory?(dir)
      @dirname = File.expand_path(dir)
      @last_file = nil
      @last_atime = nil
    end

    def directory
      @dirname
    end

    alias dirname directory

    attr_accessor :last_atime

    def inspect
      "#<#{self.class} #{@dirname}>"
    end

    def close
    end

    def new_port
      PORT_CLASS.new(next_file_name(@dirname))
    end

    def each_port
      sorted_mail_entries(@dirname).each do |ent|
        yield PORT_CLASS.new("#{@dirname}/#{ent}")
      end
      @last_atime = Time.now
    end

    alias each each_port

    def reverse_each_port
      sorted_mail_entries(@dirname).reverse_each do |ent|
        yield PORT_CLASS.new("#{@dirname}/#{ent}")
      end
      @last_atime = Time.now
    end

    alias reverse_each reverse_each_port

    # Old #each_mail returns Port, we cannot define this method now.
    #def each_mail
    #  each_port do |port|
    #    yield Mail.new(port)
    #  end
    #end

    def each_new_port(mtime = nil, &block)
      mtime ||= @last_atime
      return each_port(&block) unless mtime
      return unless File.mtime(@dirname) >= mtime

      sorted_mail_entries(@dirname).each do |ent|
        path = "#{@dirname}/#{ent}"
        yield PORT_CLASS.new(path) if File.mtime(path) > mtime
      end
      @last_atime = Time.now
    end

    private

    def sorted_mail_entries(dir)
      Dir.entries(dir)\
          .select {|ent| /\A\d+\z/ =~ ent }\
          .select {|ent| File.file?("#{dir}/#{ent}") }\
          .sort_by {|ent| ent.to_i }
    end

    # This method is not multiprocess safe
    def next_file_name(dir)
      n = @last_file
      n = sorted_mail_entries(dir).last.to_i unless n
      begin
        n += 1
      end while File.exist?("#{dir}/#{n}")
      @last_file = n
      "#{@dirname}/#{n}"
    end

  end   # MhMailbox

  MhLoader = MhMailbox


  class UNIXMbox
  
    def UNIXMbox.lock(fname, mode)
      begin
        f = File.open(fname, mode)
        f.flock File::LOCK_EX
        yield f
      ensure
        f.flock File::LOCK_UN
        f.close if f and not f.closed?
      end
    end

    class << self
      alias newobj new
      include TextUtils
    end

    def UNIXMbox.new(fname, tmpdir = nil, readonly = false)
      tmpdir = ENV['TEMP'] || ENV['TMP'] || '/tmp'
      newobj(fname, "#{tmpdir}/ruby_tmail_#{$$}_#{rand()}", readonly, false)
    end

    def UNIXMbox.static_new(fname, dir, readonly = false)
      newobj(fname, dir, readonly, true)
    end

    def initialize(fname, mhdir, readonly, static)
      @filename = fname
      @readonly = readonly
      @closed = false

      Dir.mkdir mhdir
      @real = MhMailbox.new(mhdir)
      @finalizer = UNIXMbox.mkfinal(@real, @filename, !@readonly, !static)
      ObjectSpace.define_finalizer self, @finalizer
    end

    def UNIXMbox.mkfinal(mh, mboxfile, writeback_p, cleanup_p)
      lambda {
        if writeback_p
          lock(mboxfile, "r+") {|f|
            mh.each_port do |port|
              f.puts create_from_line(port)
              port.ropen {|r|
                f.puts r.read
              }
            end
          }
        end
        if cleanup_p
          Dir.foreach(mh.dirname) do |fname|
            next if /\A\.\.?\z/ =~ fname
            File.unlink "#{mh.dirname}/#{fname}"
          end
          Dir.rmdir mh.dirname
        end
      }
    end

    # make _From line
    def UNIXMbox.create_from_line(port)
      sprintf 'From %s %s',
              fromaddr(port), time2str(File.mtime(port.filename))
    end

    def UNIXMbox.fromaddr(port)
      h = HeaderField.new_from_port(port, 'Return-Path') ||
          HeaderField.new_from_port(port, 'From') or return 'nobody'
      a = h.addrs[0] or return 'nobody'
      a.spec
    end
    private_class_method :fromaddr

    def close
      return if @closed

      ObjectSpace.undefine_finalizer self
      @finalizer.call
      @finalizer = nil
      @real = nil
      @closed = true
      @updated = nil
    end

    def each_port(&block)
      close_check
      update
      @real.each_port(&block)
    end

    alias each each_port

    def reverse_each_port(&block)
      close_check
      update
      @real.reverse_each_port(&block)
    end

    alias reverse_each reverse_each_port

    # old #each_mail returns Port
    #def each_mail( &block )
    #  each_port do |port|
    #    yield Mail.new(port)
    #  end
    #end

    def each_new_port(mtime = nil)
      close_check
      update
      @real.each_new_port(mtime) {|p| yield p }
    end

    def new_port
      close_check
      @real.new_port
    end

    private

    def close_check
      @closed and raise ArgumentError, 'accessing already closed mbox'
    end

    def update
      return if FileTest.zero?(@filename)
      return if @updated and File.mtime(@filename) < @updated
      w = nil
      port = nil
      time = nil
      UNIXMbox.lock(@filename, @readonly ? "r" : "r+") {|f|
        begin
          f.each do |line|
            if /\AFrom / =~ line
              w.close if w
              File.utime time, time, port.filename if time
              port = @real.new_port
              w = port.wopen
              time = fromline2time(line)
            else
              w.print line if w
            end
          end
        ensure
          if w and not w.closed?
            w.close
            File.utime time, time, port.filename if time
          end
        end
        f.truncate(0) unless @readonly
        @updated = Time.now
      }
    end

    def fromline2time(line)
      m = /\AFrom \S+ \w+ (\w+) (\d+) (\d+):(\d+):(\d+) (\d+)/.match(line) \
              or return nil
      Time.local(m[6].to_i, m[1], m[2].to_i, m[3].to_i, m[4].to_i, m[5].to_i)
    end

  end   # UNIXMbox

  MboxLoader = UNIXMbox


  class Maildir

    extend Mutex_m

    PORT_CLASS = MaildirPort

    @seq = 0
    def Maildir.unique_number
      synchronize {
        @seq += 1
        return @seq
      }
    end

    def initialize(dir = nil)
      @dirname = dir || ENV['MAILDIR']
      raise ArgumentError, "not directory: #{@dirname}"\
          unless FileTest.directory?(@dirname)
      @new = "#{@dirname}/new"
      @tmp = "#{@dirname}/tmp"
      @cur = "#{@dirname}/cur"
    end

    def directory
      @dirname
    end

    def inspect
      "#<#{self.class} #{@dirname}>"
    end

    def close
    end

    def each_port
      sorted_mail_entries(@cur).each do |ent|
        yield PORT_CLASS.new("#{@cur}/#{ent}")
      end
    end

    alias each each_port

    def reverse_each_port
      sorted_mail_entries(@cur).reverse_each do |ent|
        yield PORT_CLASS.new("#{@cur}/#{ent}")
      end
    end

    alias reverse_each reverse_each_port

    def new_port(&block)
      fname = nil
      tmpfname = nil
      newfname = nil
      begin
        fname = "#{Time.now.to_i}.#{$$}_#{Maildir.unique_number}.#{Socket.gethostname}"
        tmpfname = "#{@tmp}/#{fname}"
        newfname = "#{@new}/#{fname}"
      end while FileTest.exist?(tmpfname)

      if block_given?
        File.open(tmpfname, 'w', &block)
        File.rename tmpfname, newfname
        PORT_CLASS.new(newfname)
      else
        File.open(tmpfname, 'w') {|f| f.write "\n\n" }
        PORT_CLASS.new(tmpfname)
      end
    end

    def each_new_port
      sorted_mail_entries(@new).each do |ent|
        dest = "#{@cur}/#{ent}"
        File.rename "#{@new}/#{ent}", dest
        yield PORT_CLASS.new(dest)
      end
      check_tmp
    end

    TOO_OLD = 60 * 60 * 36   # 36 hour

    def check_tmp
      old = Time.now.to_i - TOO_OLD
      mail_entries(@tmp).each do |ent|
        begin
          path = "#{@tmp}/#{ent}"
          File.unlink path if File.mtime(path).to_i < old
        rescue Errno::ENOENT
          # maybe other process removed
        end
      end
    end

    private

    def sorted_mail_entries(dir)
      mail_entries(dir).sort_by {|ent| ent.slice(/\A\d+/).to_i }
    end

    def mail_entries(dir)
      Dir.entries(dir)\
          .reject {|ent| /\A\./ =~ ent }\
          .select {|ent| File.file?("#{dir}/#{ent}") }
    end
    
  end   # Maildir

  MaildirLoader = Maildir

end   # module TMail
