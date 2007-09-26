#
# port.rb
#
# Copyright (c) 1998-2004 Minero Aoki
#
# This program is free software.
# You can distribute/modify this program under the terms of
# the GNU Lesser General Public License version 2.1.
#

require 'tmail/stringio'

module TMail

  class Port
    def reproducible?
      false
    end
  end


  ###
  ### FilePort
  ###

  class FilePort < Port

    def initialize(fname)
      @path = File.expand_path(fname)
      super()
    end

    attr_reader :path
    alias filename path

    alias ident path

    def ==(other)
      other.respond_to?(:path) and @path == other.path
    end

    alias eql? ==

    def hash
      @path.hash
    end

    def inspect
      "#<#{self.class} #{@path}>"
    end

    def reproducible?
      true
    end

    def size
      File.size(@path)
    end


    def ropen(&block)
      File.open(@path, &block)
    end

    def wopen(&block)
      File.open(@path, 'w', &block)
    end

    def aopen(&block)
      File.open(@path, 'a', &block)
    end


    def read_all
      ropen {|f|
        return f.read
      }
    end


    def remove
      File.unlink @path
    end

    def move_to(port)
      begin
        File.link @path, port.path
      rescue Errno::EXDEV
        copy_to port
      end
      File.unlink @path
    end

    alias mv move_to

    def copy_to(port)
      if port.is_a?(FilePort)
        copy_file @path, port.path
      else
        File.open(@path) {|r|
          port.wopen {|w|
            while s = r.sysread(4096)
              w.write << s
            end
          }
        }
      end
    end

    alias cp copy_to

    private

    def copy_file(src, dest)
      File.open(src,  'rb') {|r|
        File.open(dest, 'wb') {|w|
          while str = r.read(2048)
            w.write str
          end
        }
      }
    end

  end


  module MailFlags

    def seen=(b)
      set_status 'S', b
    end

    def seen?
      get_status 'S'
    end

    def replied=(b)
      set_status 'R', b
    end

    def replied?
      get_status 'R'
    end

    def flagged=(b)
      set_status 'F', b
    end

    def flagged?
      get_status 'F'
    end

    private

    def procinfostr(str, tag, true_p)
      a = str.upcase.split(//)
      a.push true_p ? tag : nil
      a.delete tag unless true_p
      a.compact.sort.join('').squeeze
    end
  
  end


  class MhPort < FilePort

    include MailFlags

    private
    
    def set_status(tag, flag)
      begin
        tmpfile = "#{@path}.tmailtmp.#{$$}"
        File.open(tmpfile, 'w') {|f|
          write_status f, tag, flag
        }
        File.unlink @path
        File.link tmpfile, @path
      ensure
        File.unlink tmpfile
      end
    end

    def write_status(f, tag, flag)
      stat = ''
      File.open(@path) {|r|
        while line = r.gets
          if line.strip.empty?
            break
          elsif m = /\AX-TMail-Status:/i.match(line)
            stat = m.post_match.strip
          else
            f.print line
          end
        end

        s = procinfostr(stat, tag, flag)
        f.puts 'X-TMail-Status: ' + s unless s.empty?
        f.puts

        while s = r.read(2048)
          f.write s
        end
      }
    end

    def get_status(tag)
      File.foreach(@path) {|line|
        return false if line.strip.empty?
        if m = /\AX-TMail-Status:/i.match(line)
          return m.post_match.strip.include?(tag[0])
        end
      }
      false
    end
  
  end


  class MaildirPort < FilePort

    def move_to_new
      new = replace_dir(@path, 'new')
      File.rename @path, new
      @path = new
    end

    def move_to_cur
      new = replace_dir(@path, 'cur')
      File.rename @path, new
      @path = new
    end

    def replace_dir(path, dir)
      "#{File.dirname File.dirname(path)}/#{dir}/#{File.basename path}"
    end
    private :replace_dir


    include MailFlags

    private

    MAIL_FILE = /\A(\d+\.[\d_]+\.[^:]+)(?:\:(\d),(\w+)?)?\z/

    def set_status(tag, flag)
      if m = MAIL_FILE.match(File.basename(@path))
        s, uniq, type, info, = m.to_a
        return if type and type != '2'  # do not change anything
        newname = File.dirname(@path) + '/' +
                  uniq + ':2,' + procinfostr(info.to_s, tag, flag)
      else
        newname = @path + ':2,' + tag
      end

      File.link @path, newname
      File.unlink @path
      @path = newname
    end

    def get_status(tag)
      m = MAIL_FILE.match(File.basename(@path)) or return false
      m[2] == '2' and m[3].to_s.include?(tag[0])
    end
  
  end


  ###
  ###  StringPort
  ###

  class StringPort < Port

    def initialize(str = '')
      @buffer = str
      super()
    end

    def string
      @buffer
    end

    def to_s
      @buffer.dup
    end

    alias read_all to_s

    def size
      @buffer.size
    end

    def ==(other)
      other.is_a?(StringPort) and @buffer.equal?(other.string)
    end

    alias eql? ==

    def hash
      @buffer.object_id.hash
    end

    def inspect
      "#<#{self.class}:id=#{sprintf '0x%x', @buffer.object_id}>"
    end

    def reproducible?
      true
    end

    def ropen(&block)
      # FIXME: Should we raise ENOENT?
      raise Errno::ENOENT, "#{inspect} is already removed" unless @buffer
      StringInput.open(@buffer, &block)
    end

    def wopen(&block)
      @buffer = ''
      StringOutput.new(@buffer, &block)
    end

    def aopen(&block)
      @buffer ||= ''
      StringOutput.new(@buffer, &block)
    end

    def remove
      @buffer = nil
    end

    alias rm remove

    def copy_to(port)
      port.wopen {|f|
        f.write @buffer
      }
    end

    alias cp copy_to

    def move_to(port)
      if port.is_a?(StringPort)
        tmp = @buffer
        port.instance_eval {
          @buffer = tmp
        }
      else
        copy_to port
      end
      remove
    end

  end

end   # module TMail
