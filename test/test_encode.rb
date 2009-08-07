# encoding: utf-8 
require 'test_helper'
require 'tmail/port'
require 'tmail/encode'
require 'nkf'
require 'test/unit'

class TestEncode < Test::Unit::TestCase

  SRCS = [
"a cde あいうえおあいうえおあいうえおあいうえおあいうえお", #1
"a cde あいうえおあいうえおあいうえおあいうえおあいうえ", #2
"a cde あいうえおあいうえおあいうえおあいうえおあいう", #3
"a cde あいうえおあいうえおあいうえおあいうえおあい", #4
"a cde あいうえおあいうえおあいうえおあいうえおあ", #5
"a cde あいうえおあいうえおあいうえおあいうえお", #6 #
"a cde あいうえおあいうえおあいうえおあいうえ", #7
"a cde あいうえおあいうえおあいうえおあいう", #8
"a cde あいうえおあいうえおあいうえおあい", #9
"a cde あいうえおあいうえおあいうえおあ", #10
"a cde あいうえおあいうえおあいうえお", #11
"a cde あいうえおあいうえおあいうえ", #12
"a cde あいうえおあいうえおあいう", #13
"a cde あいうえおあいうえおあい", #14
"a cde あいうえおあいうえおあ", #15
"a cde あいうえおあいうえお", #16
"a cde あいうえおあいうえ", #17
"a cde あいうえおあいう", #18
"a cde あいうえおあい", #19
"a cde あいうえおあ", #20
"a cde あいうえお", #21
"a cde あいうえ", #22
"a cde あいう", #23
"a cde あい", #24
"a cde あ", #25
"aあa aあa aあa aあa aあa aあa" #26
  ]

  OK = [
 "a cde =?iso-2022-jp?B?GyRCJCIkJCQmJCgkKiQiJCQkJiQoJCokIiQkJCYkKCQqJCIbKEI=?=\n\t=?iso-2022-jp?B?GyRCJCQkJiQoJCokIiQkJCYkKCQqGyhC?=", #1
 "a cde =?iso-2022-jp?B?GyRCJCIkJCQmJCgkKiQiJCQkJiQoJCokIiQkJCYkKCQqJCIbKEI=?=\n\t=?iso-2022-jp?B?GyRCJCQkJiQoJCokIiQkJCYkKBsoQg==?=", #2
 "a cde =?iso-2022-jp?B?GyRCJCIkJCQmJCgkKiQiJCQkJiQoJCokIiQkJCYkKCQqJCIbKEI=?=\n\t=?iso-2022-jp?B?GyRCJCQkJiQoJCokIiQkJCYbKEI=?=", #3
 "a cde =?iso-2022-jp?B?GyRCJCIkJCQmJCgkKiQiJCQkJiQoJCokIiQkJCYkKCQqJCIbKEI=?=\n\t=?iso-2022-jp?B?GyRCJCQkJiQoJCokIiQkGyhC?=", #4
 "a cde =?iso-2022-jp?B?GyRCJCIkJCQmJCgkKiQiJCQkJiQoJCokIiQkJCYkKCQqJCIbKEI=?=\n\t=?iso-2022-jp?B?GyRCJCQkJiQoJCokIhsoQg==?=", #5
 "a cde =?iso-2022-jp?B?GyRCJCIkJCQmJCgkKiQiJCQkJiQoJCokIiQkJCYkKCQqJCIbKEI=?=\n\t=?iso-2022-jp?B?GyRCJCQkJiQoJCobKEI=?=", #6
 "a cde =?iso-2022-jp?B?GyRCJCIkJCQmJCgkKiQiJCQkJiQoJCokIiQkJCYkKCQqJCIbKEI=?=\n\t=?iso-2022-jp?B?GyRCJCQkJiQoGyhC?=", #7
 "a cde =?iso-2022-jp?B?GyRCJCIkJCQmJCgkKiQiJCQkJiQoJCokIiQkJCYkKCQqJCIbKEI=?=\n\t=?iso-2022-jp?B?GyRCJCQkJhsoQg==?=", #8
 "a cde =?iso-2022-jp?B?GyRCJCIkJCQmJCgkKiQiJCQkJiQoJCokIiQkJCYkKCQqJCIbKEI=?=\n\t=?iso-2022-jp?B?GyRCJCQbKEI=?=", #9
 "a cde =?iso-2022-jp?B?GyRCJCIkJCQmJCgkKiQiJCQkJiQoJCokIiQkJCYkKCQqJCIbKEI=?=", #10
 "a cde =?iso-2022-jp?B?GyRCJCIkJCQmJCgkKiQiJCQkJiQoJCokIiQkJCYkKCQqGyhC?=", #11
 "a cde =?iso-2022-jp?B?GyRCJCIkJCQmJCgkKiQiJCQkJiQoJCokIiQkJCYkKBsoQg==?=", #12
 'a cde =?iso-2022-jp?B?GyRCJCIkJCQmJCgkKiQiJCQkJiQoJCokIiQkJCYbKEI=?=', #13
 'a cde =?iso-2022-jp?B?GyRCJCIkJCQmJCgkKiQiJCQkJiQoJCokIiQkGyhC?=', #14
 'a cde =?iso-2022-jp?B?GyRCJCIkJCQmJCgkKiQiJCQkJiQoJCokIhsoQg==?=', #15
 'a cde =?iso-2022-jp?B?GyRCJCIkJCQmJCgkKiQiJCQkJiQoJCobKEI=?=', #16
 'a cde =?iso-2022-jp?B?GyRCJCIkJCQmJCgkKiQiJCQkJiQoGyhC?=', #17
 'a cde =?iso-2022-jp?B?GyRCJCIkJCQmJCgkKiQiJCQkJhsoQg==?=', #18
 'a cde =?iso-2022-jp?B?GyRCJCIkJCQmJCgkKiQiJCQbKEI=?=', #19
 'a cde =?iso-2022-jp?B?GyRCJCIkJCQmJCgkKiQiGyhC?=', #20
 'a cde =?iso-2022-jp?B?GyRCJCIkJCQmJCgkKhsoQg==?=', #21
 'a cde =?iso-2022-jp?B?GyRCJCIkJCQmJCgbKEI=?=', #22
 'a cde =?iso-2022-jp?B?GyRCJCIkJCQmGyhC?=', #23
 'a cde =?iso-2022-jp?B?GyRCJCIkJBsoQg==?=', #24
 'a cde =?iso-2022-jp?B?GyRCJCIbKEI=?=', #25
 "=?iso-2022-jp?B?YRskQiQiGyhCYSBhGyRCJCIbKEJhIGEbJEIkIhsoQmEgYRskQiQiGyhCYSBh?=\r\n\t=?iso-2022-jp?B?GyRCJCIbKEJhIGEbJEIkIhsoQmE=?=" #26
  ]

  unless RUBY_VERSION.match(/1.9/)
  def test_s_encode
    SRCS.each_index do |i|
      assert_equal crlf(OK[i]), 
                   TMail::Encoder.encode(NKF.nkf('-j', SRCS[i]))
    end
  end
  end

  def crlf( str )
    str.gsub(/\n|\r\n|\r/) { "\r\n" }
  end
  
  def test_wrapping_an_email_with_whitespace_at_position_zero
    # This email is a spam mail designed to break mailers...  evil.
    mail = TMail::Mail.load("#{File.dirname(__FILE__)}/fixtures/raw_attack_email_with_zero_length_whitespace")
    assert_nothing_raised(Exception) { mail.encoded }
  end

  # =?utf-8?Q? Nicolas=20Fouch=E9?= is not UTF-8, it's ISO-8859-1 !
  def test_marked_as_utf_8_but_it_is_iso_8859_1
    mail = load_fixture('marked_as_utf_8_but_it_is_iso_8859_1.txt')
    
    name = mail.to_addrs.first.name
    assert_equal ' Nicolas Fouché', TMail::Unquoter.unquote_and_convert_to(name, 'utf-8')

    # Without the patch, TMail raises:
    #  Iconv::InvalidCharacter: "\351"
    #  method iconv in quoting.rb at line 99
    #  method convert_to in quoting.rb at line 99
    #  method unquote_quoted_printable_and_convert_to in quoting.rb at line 88
    #  method unquote_and_convert_to in quoting.rb at line 72
    #  method gsub in quoting.rb at line 63
    #  method unquote_and_convert_to in quoting.rb at line 63
  end
  
  # =?iso-8859-1?b?77y5772B772O772Q772J772O772HIA==?= =?iso-8859-1?b?77y377yh77yu77yn?= is not ISO-8859-1, it's UTF-8 !
  def test_marked_as_iso_8859_1_but_it_is_utf_8
    mail = load_fixture('marked_as_iso_8859_1_but_it_is_utf_8.txt')
    
    name = mail.to_addrs.first.name
    assert_equal 'Ｙａｎｐｉｎｇ ＷＡＮＧ', TMail::Unquoter.unquote_and_convert_to(name, 'utf-8')
    # Even GMail could not detect this one :)
    
    # Without the patch, TMail returns: "ï¼¹ï½ï½ï½ï½ï½ï½  ï¼·ï¼¡ï¼®ï¼§"
  end
  
  # Be sure not to copy/paste the content of the fixture to another file, it could be automatically converted to utf-8
  def test_iso_8859_1_email_without_encoding_and_message_id
    mail = load_fixture('iso_8859_1_email_without_encoding_and_message_id.txt')
    
    text = TMail::Unquoter.unquote_and_convert_to(mail.body, 'utf-8')

    assert(text.include?('é'), 'Text content should include the "é" character')
    
    # I'm not very proud of this one, chardet detects iso-8859-2, so I have to force the encoding to iso-8859-1.
    assert(!text.include?('ŕ'), 'Text content should not iso-8859-2, "ŕ" should be "à"')
    
    # Without the patch, TMail::Unquoter.unquote_and_convert_to returns:
    #  Il semblerait que vous n'ayez pas consult� votre messagerie depuis plus
    #  d'un an. Aussi, celle-ci a �t� temporairement desactiv�e.
    #  Aucune demande n'est necessaire pour r�activer votre messagerie : la simple
    #  consultation de ce message indique que la boite est � nouveau utilisable.
  end

  protected

  def load_fixture(name)
    TMail::Mail.load(File.join('test', 'fixtures', name))
  end

end
