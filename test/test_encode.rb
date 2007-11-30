require 'test_helper'
require 'tmail/port'
require 'tmail/encode'
require 'nkf'
require 'test/unit'

class TestEncode < Test::Unit::TestCase

  SRCS = [
"a cde あいうえおあいうえおあいうえおあいうえおあいうえお",
"a cde あいうえおあいうえおあいうえおあいうえおあいうえ",
"a cde あいうえおあいうえおあいうえおあいうえおあいう",
"a cde あいうえおあいうえおあいうえおあいうえおあい",
"a cde あいうえおあいうえおあいうえおあいうえおあ",
"a cde あいうえおあいうえおあいうえおあいうえお",  #
"a cde あいうえおあいうえおあいうえおあいうえ", 
"a cde あいうえおあいうえおあいうえおあいう",
"a cde あいうえおあいうえおあいうえおあい",
"a cde あいうえおあいうえおあいうえおあ",
"a cde あいうえおあいうえおあいうえお",
"a cde あいうえおあいうえおあいうえ",
"a cde あいうえおあいうえおあいう",
"a cde あいうえおあいうえおあい",
"a cde あいうえおあいうえおあ",
"a cde あいうえおあいうえお",
"a cde あいうえおあいうえ",
"a cde あいうえおあいう",
"a cde あいうえおあい",
"a cde あいうえおあ",
"a cde あいうえお",
"a cde あいうえ",
"a cde あいう",
"a cde あい",
"a cde あ",
"aあa aあa aあa aあa"
  ]

  OK = [
  "a cde =?iso-2022-jp?B?GyRCJCIkJCQmJCgkKiQiJCQkJiQoJCokIiQkJCYbKEI=?=\n\t=?iso-2022-jp?B?GyRCJCgkKiQiJCQkJiQoJCokIiQkJCYkKCQqGyhC?=",
  "a cde =?iso-2022-jp?B?GyRCJCIkJCQmJCgkKiQiJCQkJiQoJCokIiQkJCYbKEI=?=\n\t=?iso-2022-jp?B?GyRCJCgkKiQiJCQkJiQoJCokIiQkJCYkKBsoQg==?=",
  "a cde =?iso-2022-jp?B?GyRCJCIkJCQmJCgkKiQiJCQkJiQoJCokIiQkJCYbKEI=?=\n\t=?iso-2022-jp?B?GyRCJCgkKiQiJCQkJiQoJCokIiQkJCYbKEI=?=",
 "a cde =?iso-2022-jp?B?GyRCJCIkJCQmJCgkKiQiJCQkJiQoJCokIiQkJCYbKEI=?=\n\t=?iso-2022-jp?B?GyRCJCgkKiQiJCQkJiQoJCokIiQkGyhC?=",
 "a cde =?iso-2022-jp?B?GyRCJCIkJCQmJCgkKiQiJCQkJiQoJCokIiQkJCYbKEI=?=\n\t=?iso-2022-jp?B?GyRCJCgkKiQiJCQkJiQoJCokIhsoQg==?=",
 "a cde =?iso-2022-jp?B?GyRCJCIkJCQmJCgkKiQiJCQkJiQoJCokIiQkJCYbKEI=?=\n\t=?iso-2022-jp?B?GyRCJCgkKiQiJCQkJiQoJCobKEI=?=",
 "a cde =?iso-2022-jp?B?GyRCJCIkJCQmJCgkKiQiJCQkJiQoJCokIiQkJCYbKEI=?=\n\t=?iso-2022-jp?B?GyRCJCgkKiQiJCQkJiQoGyhC?=",
 "a cde =?iso-2022-jp?B?GyRCJCIkJCQmJCgkKiQiJCQkJiQoJCokIiQkJCYbKEI=?=\n\t=?iso-2022-jp?B?GyRCJCgkKiQiJCQkJhsoQg==?=",
 "a cde =?iso-2022-jp?B?GyRCJCIkJCQmJCgkKiQiJCQkJiQoJCokIiQkJCYbKEI=?=\n\t=?iso-2022-jp?B?GyRCJCgkKiQiJCQbKEI=?=",
 "a cde =?iso-2022-jp?B?GyRCJCIkJCQmJCgkKiQiJCQkJiQoJCokIiQkJCYbKEI=?=\n\t=?iso-2022-jp?B?GyRCJCgkKiQiGyhC?=",
 "a cde =?iso-2022-jp?B?GyRCJCIkJCQmJCgkKiQiJCQkJiQoJCokIiQkJCYbKEI=?=\n\t=?iso-2022-jp?B?GyRCJCgkKhsoQg==?=",
 "a cde =?iso-2022-jp?B?GyRCJCIkJCQmJCgkKiQiJCQkJiQoJCokIiQkJCYbKEI=?=\n\t=?iso-2022-jp?B?GyRCJCgbKEI=?=",
 'a cde =?iso-2022-jp?B?GyRCJCIkJCQmJCgkKiQiJCQkJiQoJCokIiQkJCYbKEI=?=',
 'a cde =?iso-2022-jp?B?GyRCJCIkJCQmJCgkKiQiJCQkJiQoJCokIiQkGyhC?=',
 'a cde =?iso-2022-jp?B?GyRCJCIkJCQmJCgkKiQiJCQkJiQoJCokIhsoQg==?=',
 'a cde =?iso-2022-jp?B?GyRCJCIkJCQmJCgkKiQiJCQkJiQoJCobKEI=?=',
 'a cde =?iso-2022-jp?B?GyRCJCIkJCQmJCgkKiQiJCQkJiQoGyhC?=',
 'a cde =?iso-2022-jp?B?GyRCJCIkJCQmJCgkKiQiJCQkJhsoQg==?=',
 'a cde =?iso-2022-jp?B?GyRCJCIkJCQmJCgkKiQiJCQbKEI=?=',
 'a cde =?iso-2022-jp?B?GyRCJCIkJCQmJCgkKiQiGyhC?=',
 'a cde =?iso-2022-jp?B?GyRCJCIkJCQmJCgkKhsoQg==?=',
 'a cde =?iso-2022-jp?B?GyRCJCIkJCQmJCgbKEI=?=',
 'a cde =?iso-2022-jp?B?GyRCJCIkJCQmGyhC?=',
 'a cde =?iso-2022-jp?B?GyRCJCIkJBsoQg==?=',
 'a cde =?iso-2022-jp?B?GyRCJCIbKEI=?=',
 "=?iso-2022-jp?B?YRskQiQiGyhCYSBhGyRCJCIbKEJhIGEbJEIkIhsoQmEgYQ==?=\n\t=?iso-2022-jp?B?GyRCJCIbKEJh?="
  ]

  def test_s_encode
    SRCS.each_index do |i|
      assert_equal crlf(OK[i]), 
                   TMail::Encoder.encode(NKF.nkf('-j', SRCS[i]))
    end
  end

  def crlf( str )
    str.gsub(/\n|\r\n|\r/) { "\r\n" }
  end

end
