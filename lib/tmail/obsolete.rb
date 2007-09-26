#
# obsolete.rb
#
# Copyright (c) 1998-2004 Minero Aoki
#
# This program is free software.
# You can distribute/modify this program under the terms of
# the GNU Lesser General Public License version 2.1.
#

require 'tmail/textutils'
require 'tmail/utils'


module TMail

  # mail.rb
  class Mail
    class << self
      alias loadfrom load
      alias load_from load
    end

    alias include? key?
    alias has_key? key?

    def values
      result = []
      each_field do |f|
        result.push f
      end
      result
    end

    def value?(val)
      return false unless val.is_a?(HeaderField)
      [@header[val.name.downcase]].flatten.include?(val)
    end

    alias has_value? value?
  end


  # facade.rb
  class Mail
    def from_addr(default = nil)
      addr, = from_addrs(nil)
      addr || default
    end

    alias from_address= from_addrs=

    def from_phrase(default = nil)
      if a = from_addr(nil)
        a.phrase
      else
        default
      end
    end

    alias msgid  message_id
    alias msgid= message_id=

    alias each_dest each_destination
  end


  # address.rb
  class Address
    alias route routes
    alias addr spec

    def spec=(str)
      @local, @domain = str.split(/@/,2).map {|s| s.split(/\./) }
    end

    alias addr= spec=
    alias address= spec=
  end


  # mbox.rb
  class MhMailbox
    alias new_mail new_port
    alias each_mail each_port
    alias each_newmail each_new_port
  end
  class UNIXMbox
    alias new_mail new_port
    alias each_mail each_port
    alias each_newmail each_new_port
  end
  class Maildir
    alias new_mail new_port
    alias each_mail each_port
    alias each_newmail each_new_port
  end


  # textutils.rb
  extend TextUtils

  class << self
    public :message_id?
    public :new_boundary
    public :new_message_id

    alias msgid?    message_id?
    alias boundary  new_boundary
    alias msgid     new_message_id
    alias new_msgid new_message_id
  end

  def Mail.boundary
    ::TMail.new_boundary
  end

  def Mail.msgid
    ::TMail.new_message_id
  end

end   # module TMail
