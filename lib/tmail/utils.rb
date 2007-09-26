#
# utils.rb
#
# Copyright (c) 1998-2004 Minero Aoki
#
# This program is free software.
# You can distribute/modify this program under the terms of
# the GNU Lesser General Public License version 2.1.
#

require 'tmail/textutils'
require 'socket'

module TMail

  extend TextUtils

  def TMail.new_message_id(fqdn = nil)
    fqdn ||= ::Socket.gethostname
    "<#{random_tag()}@#{fqdn}.tmail>"
  end

end
