#
# mail.rb
#
# Copyright (c) 1998-2004 Minero Aoki
#
# This program is free software.
# You can distribute/modify this program under the terms of
# the GNU Lesser General Public License version 2.1.
#

require 'tmail/encode'
require 'tmail/header'
require 'tmail/port'
require 'tmail/config'
require 'tmail/textutils'

module TMail

  class BadMessage < StandardError; end


  class Mail

    def Mail.load(fname)
      new(FilePort.new(fname))
    end

    def Mail.parse(str)
      new(StringPort.new(str))
    end

    def initialize(port = nil, conf = DEFAULT_CONFIG)
      @port = port || StringPort.new
      @config = Config.to_config(conf)

      @header      = {}
      @body_port   = nil
      @body_parsed = false
      @epilogue    = ''
      @parts       = []

      @port.ropen {|f|
        parse_header f
        parse_body f unless @port.reproducible?
      }
    end

    attr_reader :port

    def inspect
      "\#<#{self.class} port=#{@port.inspect} bodyport=#{@body_port.inspect}>"
    end

    #
    # to_s interfaces
    #

    public

    include StrategyInterface

    def write_back(eol = "\n", charset = 'e')
      parse_body
      @port.wopen {|stream|
        encoded eol, charset, stream
      }
    end

    def accept(strategy)
      with_multipart_encoding(strategy) {
        ordered_each do |name, field|
          next if field.empty?
          strategy.header_name canonical(name)
          field.accept strategy
          strategy.puts
        end
        strategy.puts
        body_port().ropen {|r|
          strategy.write r.read
        }
      }
    end

    private

    def canonical(name)
      name.split(/-/).map {|s| s.capitalize }.join('-')
    end

    def with_multipart_encoding(strategy)
      if parts().empty?    # DO NOT USE @parts
        yield

      else
        bound = (type_param('boundary') || ::TMail.new_boundary)
        if @header.key?('content-type')
          @header['content-type'].params['boundary'] = bound
        else
          store 'Content-Type', %<multipart/mixed; boundary="#{bound}">
        end

        yield

        parts().each do |m|
          strategy.puts
          strategy.puts '--' + bound
          m.accept strategy
        end
        strategy.puts
        strategy.puts '--' + bound + '--'
        strategy.write epilogue()
      end
    end

    ###
    ### High level utilities
    ###

    public

    def friendly_from(default = nil)
      h = @header['from']
      a, = h.addrs
      return default unless a
      return a.phrase if a.phrase
      return h.comments.join(' ') unless h.comments.empty?
      a.spec
    end

    def from_address(default = nil)
      from([]).first || default
    end

    def destinations(default = nil)
      result = to([]) + cc([]) + bcc([])
      return default if result.empty?
      result
    end

    def each_destination(&block)
      destinations([]).each(&block)
    end

    alias each_dest each_destination

    def reply_addresses(default = nil)
      reply_to_addrs(nil) or from_addrs(nil) or default
    end

    def error_reply_addresses(default = nil)
      if s = sender(nil)
        [s]
      else
        from_addrs(default)
      end
    end

    def base64_encode
      store 'Content-Transfer-Encoding', 'Base64'
      self.body = Base64.folding_encode(self.body)
    end

    def base64_decode
      if /base64/i =~ self.transfer_encoding('')
        store 'Content-Transfer-Encoding', '8bit'
        self.body = Base64.decode(self.body, @config.strict_base64decode?)
      end
    end

    def multipart?
      main_type('').downcase == 'multipart'
    end

    def create_reply
      mail = TMail::Mail.new
      mail.subject = 'Re: ' + subject('').sub(/\A(?:\[[^\]]+\])?(?:\s*Re:)*\s*/i, '')
      mail.to_addrs = reply_addresses([])
      mail.in_reply_to = [message_id(nil)].compact
      mail.references = references([]) + [message_id(nil)].compact
      mail.mime_version = '1.0'
      mail
    end

    ###
    ### Header access facades
    ###

    include TextUtils

    public

    def header_string(name, default = nil)
      h = @header[name.downcase] or return default
      h.to_s
    end

    #
    # date time
    #

    def date(default = nil)
      h = @header['date'] or return default
      h.date
    end

    def date=(time)
      if time
        store 'Date', time2str(time)
      else
        @header.delete 'date'
      end
      time
    end

    def strftime(fmt, default = nil)
      t = date or return default
      t.strftime(fmt)
    end

    #
    # destination
    #

    def to_addrs(default = nil)
      h = @header['to'] or return default
      h.addrs
    end

    def cc_addrs(default = nil)
      h = @header['cc'] or return default
      h.addrs
    end

    def bcc_addrs(default = nil)
      h = @header['bcc'] or return default
      h.addrs
    end

    def to_addrs=(arg)
      set_addrfield 'to', arg
    end

    def cc_addrs=(arg)
      set_addrfield 'cc', arg
    end

    def bcc_addrs=(arg)
      set_addrfield 'bcc', arg
    end

    def to(default = nil)
      addrs2specs(to_addrs(nil)) || default
    end

    def cc(default = nil)
      addrs2specs(cc_addrs(nil)) || default
    end

    def bcc(default = nil)
      addrs2specs(bcc_addrs(nil)) || default
    end

    def to=(*strs)
      set_string_array_attr 'To', strs
    end

    def cc=(*strs)
      set_string_array_attr 'Cc', strs
    end

    def bcc=(*strs)
      set_string_array_attr 'Bcc', strs
    end

    #
    # originator
    #

    def from_addrs(default = nil)
      if h = @header['from']
        h.addrs
      else
        default
      end
    end

    def from_addrs=(arg)
      set_addrfield 'from', arg
    end

    def from(default = nil)
      addrs2specs(from_addrs(nil)) || default
    end

    def from=(*strs)
      set_string_array_attr 'From', strs
    end


    def reply_to_addrs(default = nil)
      h = @header['reply-to'] or return default
      h.addrs
    end

    def reply_to_addrs=(arg)
      set_addrfield 'reply-to', arg
    end

    def reply_to(default = nil)
      addrs2specs(reply_to_addrs(nil)) || default
    end

    def reply_to=(*strs)
      set_string_array_attr 'Reply-To', strs
    end


    def sender_addr(default = nil)
      f = @header['sender'] or return default
      f.addr || default
    end

    def sender_addr=(addr)
      if addr
        h = HeaderField.internal_new('sender', @config)
        h.addr = addr
        @header['sender'] = h
      else
        @header.delete 'sender'
      end
      addr
    end

    def sender(default)
      f = @header['sender'] or return default
      a = f.addr            or return default
      a.spec
    end

    def sender=(str)
      set_string_attr 'Sender', str
    end

    #
    # subject
    #

    def subject(default = nil)
      h = @header['subject'] or return default
      h.body
    end

    def subject=(str)
      set_string_attr 'Subject', str
    end

    #
    # identity & threading
    #

    def message_id(default = nil)
      h = @header['message-id'] or return default
      h.id || default
    end

    def message_id=(str)
      set_string_attr 'Message-Id', str
    end

    def in_reply_to(default = nil)
      h = @header['in-reply-to'] or return default
      h.ids
    end

    def in_reply_to=(*idstrs)
      set_string_array_attr 'In-Reply-To', idstrs
    end

    def references(default = nil)
      h = @header['references'] or return default
      h.refs
    end

    def references=(*strs)
      set_string_array_attr 'References', strs
    end

    #
    # MIME headers
    #

    def mime_version(default = nil)
      h = @header['mime-version'] or return default
      h.version || default
    end

    def mime_version=(m, opt = nil)
      if opt
        if h = @header['mime-version']
          h.major = m
          h.minor = opt
        else
          store 'Mime-Version', "#{m}.#{opt}"
        end
      else
        store 'Mime-Version', m
      end
      m
    end


    def content_type(default = nil)
      h = @header['content-type'] or return default
      h.content_type || default
    end

    def main_type(default = nil)
      h = @header['content-type'] or return default
      h.main_type || default
    end

    def sub_type(default = nil)
      h = @header['content-type'] or return default
      h.sub_type || default
    end

    def set_content_type(str, sub = nil, param = nil)
      if sub
        main, sub = str, sub
      else
        main, sub = str.split(%r</>, 2)
        raise ArgumentError, "sub type missing: #{str.inspect}" unless sub
      end
      if h = @header['content-type']
        h.main_type = main
        h.sub_type  = sub
        h.params.clear
      else
        store 'Content-Type', "#{main}/#{sub}"
      end
      @header['content-type'].params.replace param if param

      str
    end

    alias content_type= set_content_type
    
    def type_param(name, default = nil)
      h = @header['content-type'] or return default
      h[name] || default
    end

    def charset(default = nil)
      h = @header['content-type'] or return default
      h['charset'] || default
    end

    def charset=(str)
      if str
        if h = @header[ 'content-type' ]
          h['charset'] = str
        else
          store 'Content-Type', "text/plain; charset=#{str}"
        end
      end
      str
    end


    def transfer_encoding(default = nil)
      if h = @header['content-transfer-encoding']
        h.encoding || default
      else
        default
      end
    end

    def transfer_encoding=(str)
      set_string_attr 'Content-Transfer-Encoding', str
    end

    alias encoding                   transfer_encoding
    alias encoding=                  transfer_encoding=
    alias content_transfer_encoding  transfer_encoding
    alias content_transfer_encoding= transfer_encoding=


    def disposition(default = nil)
      if h = @header['content-disposition']
        h.disposition || default
      else
        default
      end
    end

    alias content_disposition     disposition

    def set_disposition(pos, params = nil)
      @header.delete 'content-disposition'
      return pos unless pos
      store('Content-Disposition', pos)
      @header['content-disposition'].params.replace params if params
      pos
    end

    alias disposition=            set_disposition
    alias set_content_disposition set_disposition
    alias content_disposition=    set_disposition
    
    def disposition_param(name, default = nil)
      if h = @header['content-disposition']
        h[name] || default
      else
        default
      end
    end

    #
    # sub routines
    #

    def set_string_array_attr(key, strs)
      strs.flatten!
      if strs.empty?
        @header.delete key.downcase
      else
        store key, strs.join(', ')
      end
      strs
    end
    private :set_string_array_attr

    def set_string_attr(key, str)
      if str
        store key, str
      else
        @header.delete key.downcase
      end
      str
    end
    private :set_string_attr

    def set_addrfield(name, arg)
      if arg
        h = HeaderField.internal_new(name, @config)
        h.addrs.replace [arg].flatten
        @header[name] = h
      else
        @header.delete name
      end
      arg
    end
    private :set_addrfield

    def addrs2specs(addrs)
      return nil unless addrs
      list = addrs.map {|addr|
          if addr.address_group?
          then addr.map {|a| a.spec }
          else addr.spec
          end
      }.flatten
      return nil if list.empty?
      list
    end
    private :addrs2specs

    ###
    ### Direct Header Access
    ###

    public

    ALLOW_MULTIPLE = {
      'received'          => true,
      'resent-date'       => true,
      'resent-from'       => true,
      'resent-sender'     => true,
      'resent-to'         => true,
      'resent-cc'         => true,
      'resent-bcc'        => true,
      'resent-message-id' => true,
      'comments'          => true,
      'keywords'          => true
    }
    USE_ARRAY = ALLOW_MULTIPLE

    def header
      @header.dup
    end

    def [](key)
      @header[key.downcase]
    end

    alias fetch []

    def []=(key, val)
      dkey = key.downcase
      if val.nil?
        @header.delete dkey
        return nil
      end
      case val
      when String
        header = new_hf(key, val)
      when HeaderField
        ;
      when Array
        raise BadMessage, "multiple #{key}: header fields exist"\
            unless ALLOW_MULTIPLE.include?(dkey)
        @header[dkey] = val
        return val
      else
        header = new_hf(key, val.to_s)
      end
      if ALLOW_MULTIPLE.include? dkey
        (@header[dkey] ||= []).push header
      else
        @header[dkey] = header
      end

      val
    end

    alias store []=

    def each_header
      @header.each do |key, val|
        [val].flatten.each {|v| yield key, v }
      end
    end

    alias each_pair each_header

    def each_header_name(&block)
      @header.each_key(&block)
    end

    alias each_key each_header_name

    def each_field(&block)
      @header.values.flatten.each(&block)
    end

    alias each_value each_field

    FIELD_ORDER = %w(
      return-path received
      resent-date resent-from resent-sender resent-to
      resent-cc resent-bcc resent-message-id
      date from sender reply-to to cc bcc
      message-id in-reply-to references
      subject comments keywords
      mime-version content-type content-transfer-encoding
      content-disposition content-description
    )

    def ordered_each
      list = @header.keys
      FIELD_ORDER.each do |name|
        if list.delete(name)
          [@header[name]].flatten.each {|v| yield name, v }
        end
      end
      list.each do |name|
        [@header[name]].flatten.each {|v| yield name, v }
      end
    end

    def clear
      @header.clear
    end

    def delete(key)
      @header.delete key.downcase
    end

    def delete_if
      @header.delete_if {|key, val|
        if val.is_a?(Array)
          val.delete_if {|v| yield key, v }
          val.empty?
        else
          yield key, val
        end
      }
    end

    def keys
      @header.keys
    end

    def key?(key)
      @header.key?(key.downcase)
    end

    def values_at(*args)
      args.map {|k| @header[k.downcase] }.flatten
    end

    alias indexes values_at
    alias indices values_at

    private

    def parse_header(f)
      name = field = nil
      unixfrom = nil

      while line = f.gets
        case line
        when /\A[ \t]/             # continue from prev line
          raise SyntaxError, 'mail is began by space' unless field
          field << ' ' << line.strip
        when /\A([^\: \t]+):\s*/   # new header line
          add_hf name, field if field
          name = $1
          field = $' #.strip
        when /\A\-*\s*\z/          # end of header
          add_hf name, field if field
          name = field = nil
          break
        when /\AFrom (\S+)/
          unixfrom = $1
        else
          raise SyntaxError, "wrong mail header: '#{line.inspect}'"
        end
      end
      add_hf name, field if name

      if unixfrom
        add_hf 'Return-Path', "<#{unixfrom}>" unless @header['return-path']
      end
    end

    def add_hf(name, field)
      key = name.downcase
      field = new_hf(name, field)

      if ALLOW_MULTIPLE.include? key
        (@header[key] ||= []).push field
      else
        @header[key] = field
      end
    end

    def new_hf(name, field)
      HeaderField.new(name, field, @config)
    end

    ###
    ### Message Body
    ###

    public

    def body_port
      parse_body
      @body_port
    end

    def each(&block)
      body_port().ropen {|f| f.each(&block) }
    end

    def body
      parse_body
      @body_port.ropen {|f|
        return f.read
      }
    end

    def body=(str)
      parse_body
      @body_port.wopen {|f| f.write str }
      str
    end

    alias preamble  body
    alias preamble= body=

    def epilogue
      parse_body
      @epilogue.dup
    end

    def epilogue=(str)
      parse_body
      @epilogue = str
      str
    end

    def parts
      parse_body
      @parts
    end
    
    def each_part(&block)
      parts().each(&block)
    end

    private

    def parse_body(f = nil)
      return if @body_parsed
      if f
        parse_body_0 f
      else
        @port.ropen {|f|
          skip_header f
          parse_body_0 f
        }
      end
      @body_parsed = true
    end

    def skip_header(f)
      while line = f.gets
        return if /\A[\r\n]*\z/ =~ line
      end
    end

    def parse_body_0(f)
      if multipart?
        read_multipart f
      else
        read_singlepart f
      end
    end

    def read_singlepart(f)
      @body_port = @config.new_body_port(self)
      @body_port.wopen {|w|
        w.write f.read
      }
    end
    
    def read_multipart(src)
      bound = type_param('boundary')
      return read_singlepart(src) unless bound
      is_sep = /\A--#{Regexp.quote(bound)}(?:--)?[ \t]*(?:\n|\r\n|\r)/
      lastbound = "--#{bound}--"

      ports = [ @config.new_preamble_port(self) ]
      begin
        f = ports.last.wopen
        while line = src.gets
          if is_sep =~ line
            f.close
            break if line.strip == lastbound
            ports.push @config.new_part_port(self)
            f = ports.last.wopen
          else
            f << line
          end
        end
        @epilogue = (src.read || '')
      ensure
        f.close if f and not f.closed?
      end

      @body_port = ports.shift
      @parts = ports.map {|p| self.class.new(p, @config) }
    end

  end   # class Mail

end   # module TMail
