#
# scanner.rb
#
# Copyright (c) 1998-2004 Minero Aoki
#
# This program is free software.
# You can distribute/modify this program under the terms of
# the GNU Lesser General Public License version 2.1.
#

require 'tmail/textutils'

module TMail
  require 'tmail/scanner_r.rb'
  begin
    raise LoadError, 'Turn off Ruby extention by user choice' if ENV['NORUBYEXT']
    require 'tmail/scanner_c.so'
    Scanner = Scanner_C
  rescue LoadError
    Scanner = Scanner_R
  end
end
