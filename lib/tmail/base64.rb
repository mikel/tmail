# = Base64 handling class
#
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

begin
  raise LoadError, 'Turned off native extentions by user choice' if ENV['NORUBYEXT']
  require 'tmail/base64_c'
rescue LoadError
  require 'tmail/base64_r'
end

# module Base64
#
#   def self.folding_encode( str, eol = "\n", limit = 60 )
#     b64encode( str, limit )
#   end
#
#   def self.encode( str )
#     encode64( str )
#   end
#
#   def self.decode( str, strict = false )
#     if strict
#       decode_b( str )
#     else
#       decode64( str )
#     end
#   end
#
#   #begin
#   #  require('base64.so')  # TODO technically this is bad b/c of .dll (?)
#   #  alias folding_encode c_folding_encode
#   #  alias encode         c_encode
#   #  alias decode         c_decode
#   #  class << self
#   #    alias folding_encode c_folding_encode
#   #    alias encode         c_encode
#   #    alias decode         c_decode
#   #  end
#   #rescue LoadError
#   #  alias folding_encode rb_folding_encode
#   #  alias encode         rb_encode
#   #  alias decode         rb_decode
#   #  class << self
#   #    alias folding_encode rb_folding_encode
#   #    alias encode         rb_encode
#   #    alias decode         rb_decode
#   #  end
#   #end
#
# end
