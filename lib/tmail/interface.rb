=begin rdoc

= Facade.rb Provides an interface to the TMail object

=end
#--
# Copyright (c) 1998-2003 Minero Aoki <aamine@loveruby.net>
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
# Note: Originally licensed under LGPL v2+. Using MIT license for Rails
# with permission of Minero Aoki.
#++

require 'tmail/utils'

module TMail

  class Mail

    # Allows you to query the mail object with a string to get the contents
    # of the field you want.
    # 
    # Returns a string of the exact contnts of the field
    # 
    #  mail.from = "mikel <mikel@lindsaar.net>"
    #  mail.header_string("From") #=> "mikel <mikel@lindsaar.net>"
    def header_string( name, default = nil )
      h = @header[name.downcase] or return default
      h.to_s
    end

    ###--
    ### attributes
    ###++

    include TextUtils

    def set_string_array_attr( key, strs )
      strs.flatten!
      if strs.empty?
        @header.delete key.downcase
      else
        store key, strs.join(', ')
      end
      strs
    end
    private :set_string_array_attr

    def set_string_attr( key, str )
      if str
        store key, str
      else
        @header.delete key.downcase
      end
      str
    end
    private :set_string_attr

    def set_addrfield( name, arg )
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

    def addrs2specs( addrs )
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

    #--
    # date time
    #++

    # Returns the date of the email message as per the "date" header value or returns
    # nil by default (if no date field exists).  
    # 
    # You can also pass whatever default you want into this method and it will return 
    # that instead of nil if there is no date already set. 
    def date( default = nil )
      if h = @header['date']
        h.date
      else
        default
      end
    end

    # Set the date of the mail object.
    # 
    # Accepts a Time Object
    # 
    #  now = Time.now
    #  mail.date = now
    #  mail.date #=> (mail formatted time)
    def date=( time )
      if time
        store 'Date', time2str(time)
      else
        @header.delete 'date'
      end
      time
    end

    # Returns the time of the mail message formatted to your taste using a 
    # strftime format string.  If no date set returns nil by default or whatever value
    # you pass as the second optional parameter.
    # 
    #  time = Time.now # (on Nov 16 2007)
    #  mail.date = time
    #  mail.strftime("%D") #=> "11/16/07"
    def strftime( fmt, default = nil )
      if t = date
        t.strftime(fmt)
      else
        default
      end
    end

    #--
    # destination
    #++

    # Return the addresses in the "to" field of the mail object header.
    # 
    # If the to field does not exist, will return nil by default or the value you
    # pass as the optional parameter
    def to_addrs( default = nil )
      if h = @header['to']
        h.addrs
      else
        default
      end
    end

    # Return the addresses in the "cc" field of the mail object header.
    # 
    # If the cc field does not exist, will return nil by default or the value you
    # pass as the optional parameter
    def cc_addrs( default = nil )
      if h = @header['cc']
        h.addrs
      else
        default
      end
    end

    # Return the addresses in the "bcc" field of the mail object header.
    # 
    # If the bcc field does not exist, will return nil by default or the value you
    # pass as the optional parameter
    def bcc_addrs( default = nil )
      if h = @header['bcc']
        h.addrs
      else
        default
      end
    end

    # Set the to field of the Mail object header to equal the passed in string.
    # 
    # TMail will parse your contents and turn it into an TMail::Address object before
    # assigning it to the mail message.
    def to_addrs=( arg )
      set_addrfield 'to', arg
    end

    # Set the cc field of the Mail object header to equal the passed in string.
    # 
    # TMail will parse your contents and turn it into an TMail::Address object before
    # assigning it to the mail message.
    def cc_addrs=( arg )
      set_addrfield 'cc', arg
    end

    # Set the bcc field of the Mail object header to equal the passed in string.
    # 
    # TMail will parse your contents and turn it into an TMail::Address object before
    # assigning it to the mail message.
    def bcc_addrs=( arg )
      set_addrfield 'bcc', arg
    end

    def to( default = nil )
      addrs2specs(to_addrs(nil)) || default
    end

    def cc( default = nil )
      addrs2specs(cc_addrs(nil)) || default
    end

    def bcc( default = nil )
      addrs2specs(bcc_addrs(nil)) || default
    end

    def to=( *strs )
      set_string_array_attr 'To', strs
    end

    def cc=( *strs )
      set_string_array_attr 'Cc', strs
    end

    def bcc=( *strs )
      set_string_array_attr 'Bcc', strs
    end

    #--
    # originator
    #++

    def from_addrs( default = nil )
      if h = @header['from']
        h.addrs
      else
        default
      end
    end

    def from_addrs=( arg )
      set_addrfield 'from', arg
    end

    def from( default = nil )
      addrs2specs(from_addrs(nil)) || default
    end

    def from=( *strs )
      set_string_array_attr 'From', strs
    end

    def friendly_from( default = nil )
      h = @header['from']
      a, = h.addrs
      return default unless a
      return a.phrase if a.phrase
      return h.comments.join(' ') unless h.comments.empty?
      a.spec
    end


    def reply_to_addrs( default = nil )
      if h = @header['reply-to']
        h.addrs.blank? ? default : h.addrs
      else
        default
      end
    end

    def reply_to_addrs=( arg )
      set_addrfield 'reply-to', arg
    end

    def reply_to( default = nil )
      addrs2specs(reply_to_addrs(nil)) || default
    end

    def reply_to=( *strs )
      set_string_array_attr 'Reply-To', strs
    end


    def sender_addr( default = nil )
      f = @header['sender'] or return default
      f.addr                or return default
    end

    def sender_addr=( addr )
      if addr
        h = HeaderField.internal_new('sender', @config)
        h.addr = addr
        @header['sender'] = h
      else
        @header.delete 'sender'
      end
      addr
    end

    def sender( default )
      f = @header['sender'] or return default
      a = f.addr            or return default
      a.spec
    end

    def sender=( str )
      set_string_attr 'Sender', str
    end


    #--
    # subject
    #++

    def subject( default = nil )
      if h = @header['subject']
        h.body
      else
        default
      end
    end
    alias quoted_subject subject

    def subject=( str )
      set_string_attr 'Subject', str
    end

    #--
    # identity & threading
    #++

    def message_id( default = nil )
      if h = @header['message-id']
        h.id || default
      else
        default
      end
    end

    def message_id=( str )
      set_string_attr 'Message-Id', str
    end

    def in_reply_to( default = nil )
      if h = @header['in-reply-to']
        h.ids
      else
        default
      end
    end

    def in_reply_to=( *idstrs )
      set_string_array_attr 'In-Reply-To', idstrs
    end

    def references( default = nil )
      if h = @header['references']
        h.refs
      else
        default
      end
    end

    def references=( *strs )
      set_string_array_attr 'References', strs
    end

    #--
    # MIME headers
    #++ 

    def mime_version( default = nil )
      if h = @header['mime-version']
        h.version || default
      else
        default
      end
    end

    def mime_version=( m, opt = nil )
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

    def content_type( default = nil )
      if h = @header['content-type']
        h.content_type || default
      else
        default
      end
    end

    def main_type( default = nil )
      if h = @header['content-type']
        h.main_type || default
      else
        default
      end
    end

    def sub_type( default = nil )
      if h = @header['content-type']
        h.sub_type || default
      else
        default
      end
    end

    def set_content_type( str, sub = nil, param = nil )
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
    
    def type_param( name, default = nil )
      if h = @header['content-type']
        h[name] || default
      else
        default
      end
    end

    def charset( default = nil )
      if h = @header['content-type']
        h['charset'] or default
      else
        default
      end
    end

    def charset=( str )
      if str
        if h = @header[ 'content-type' ]
          h['charset'] = str
        else
          store 'Content-Type', "text/plain; charset=#{str}"
        end
      end
      str
    end

    def transfer_encoding( default = nil )
      if h = @header['content-transfer-encoding']
        h.encoding || default
      else
        default
      end
    end

    def transfer_encoding=( str )
      set_string_attr 'Content-Transfer-Encoding', str
    end

    alias encoding                   transfer_encoding
    alias encoding=                  transfer_encoding=
    alias content_transfer_encoding  transfer_encoding
    alias content_transfer_encoding= transfer_encoding=

    def disposition( default = nil )
      if h = @header['content-disposition']
        h.disposition || default
      else
        default
      end
    end

    alias content_disposition     disposition

    def set_disposition( str, params = nil )
      if h = @header['content-disposition']
        h.disposition = str
        h.params.clear
      else
        store('Content-Disposition', str)
        h = @header['content-disposition']
      end
      h.params.replace params if params
    end

    alias disposition=            set_disposition
    alias set_content_disposition set_disposition
    alias content_disposition=    set_disposition
    
    def disposition_param( name, default = nil )
      if h = @header['content-disposition']
        h[name] || default
      else
        default
      end
    end

    # Destructively convert the Mail object's body into a Base64 encoded email
    # returning the modified Mail object
    def base64_encode!
      store 'Content-Transfer-Encoding', 'Base64'
      self.body = Base64.folding_encode(self.body)
    end

    # ==Depreciation warning
    # base64_encode will return the body encoded, not modify the message body in 
    # future versions of TMail
    alias :base64_encode :base64_encode!

    # Destructively convert the Mail object's body into a Base64 decoded email
    # returning the modified Mail object
    def base64_decode!
      if /base64/i === self.transfer_encoding('')
        store 'Content-Transfer-Encoding', '8bit'
        self.body = Base64.decode(self.body, @config.strict_base64decode?)
      end
    end

    # ==Depreciation warning
    # base64_decode will return the body decoded, not modify the message body in 
    # future versions of TMail
    alias :base64_decode :base64_decode!

    # Returns an array of each destination in the email message including to: cc: or bcc:
    #  mail.to = "Mikel <mikel@lindsaar.net>"
    #  mail.cc = "Trans <t@t.com>"
    #  mail.bcc = "bob <bob@me.com>"
    #  mail.destinations #=> ["mikel@lindsaar.net", "t@t.com", "bob@me.com"]
    def destinations( default = nil )
      ret = []
      %w( to cc bcc ).each do |nm|
        if h = @header[nm]
          h.addrs.each {|i| ret.push i.address }
        end
      end
      ret.empty? ? default : ret
    end

    # Yields a block of destination, yielding each as a string.
    #  (from the destinations example)
    #  mail.each_destination { |d| puts "#{d.class}: #{d}" }
    #  String: mikel@lindsaar.net
    #  String: t@t.com
    #  String: bob@me.com
    def each_destination( &block )
      destinations([]).each do |i|
        if Address === i
          yield i
        else
          i.each(&block)
        end
      end
    end

    alias each_dest each_destination

    # Returns an array of reply to addresses that the Mail object has, 
    # or if the Mail message has no reply-to, returns an array of the
    # Mail objects from addresses.  Else returns the default which can
    # either be passed as a parameter or defaults to nil
    # 
    # Example:
    #  mail.from = "Mikel <mikel@lindsaar.net>"
    #  mail.reply_to = nil
    #  mail.reply_addresses #=> [""]  
    # 
    def reply_addresses( default = nil )
      reply_to_addrs(nil) or from_addrs(nil) or default
    end

    # Returns the "sender" field as an array -> useful to find out who to 
    # send an error email to.
    def error_reply_addresses( default = nil )
      if s = sender(nil)
        [s]
      else
        from_addrs(default)
      end
    end

    # Returns true if the Mail object is a multipart message
    def multipart?
      main_type('').downcase == 'multipart'
    end

    # Creates a new email in reply to self.  Sets the In-Reply-To and
    # References headers for you automagically.
    #
    # Example:
    #  mail = TMail::Mail.load("my_email")
    #  reply_email = mail.create_reply
    #  reply_email.class         #=> TMail::Mail
    #  reply_email.references  #=> ["<d3b8cf8e49f04480850c28713a1f473e@lindsaar.net>"]
    #  reply_email.in_reply_to #=> ["<d3b8cf8e49f04480850c28713a1f473e@lindsaar.net>"]
    def create_reply
      setup_reply create_empty_mail()
    end

    # Creates a new email in reply to self.  Sets the In-Reply-To and
    # References headers for you automagically.
    #
    # Example:
    #  mail = TMail::Mail.load("my_email")
    #  forward_email = mail.create_forward
    #  forward_email.class         #=> TMail::Mail
    #  forward_email.content_type  #=> "multipart/mixed"
    #  forward_email.body          #=> "Attachment: (unnamed)"
    #  forward_email.encoded       #=> Returns the original email as a MIME attachment
    def create_forward
      setup_forward create_empty_mail()
    end

    private

    def create_empty_mail
      self.class.new(StringPort.new(''), @config)
    end

    def setup_reply( mail )
      if tmp = reply_addresses(nil)
        mail.to_addrs = tmp
      end

      mid = message_id(nil)
      tmp = references(nil) || []
      tmp.push mid if mid
      mail.in_reply_to = [mid] if mid
      mail.references = tmp unless tmp.empty?
      mail.subject = 'Re: ' + subject('').sub(/\A(?:\[[^\]]+\])?(?:\s*Re:)*\s*/i, '')
      mail.mime_version = '1.0'
      mail
    end

    def setup_forward( mail )
      m = Mail.new(StringPort.new(''))
      m.body = decoded
      m.set_content_type 'message', 'rfc822'
      m.encoding = encoding('7bit')
      mail.parts.push m
      # call encoded to reparse the message
      mail.encoded
      mail
    end

  end   # class Mail

end   # module TMail
