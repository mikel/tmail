require 'test_helper'
require 'tmail'

class TestAttachments < Test::Unit::TestCase

  def test_attachment
    mail = TMail::Mail.new
    mail.mime_version = "1.0"
    mail.set_content_type 'multipart', 'mixed', {'boundary' => 'Apple-Mail-13-196941151'}
    mail.body =<<HERE
--Apple-Mail-13-196941151
Content-Transfer-Encoding: quoted-printable
Content-Type: text/plain;
	charset=ISO-8859-1;
	delsp=yes;
	format=flowed

This is the first part.

--Apple-Mail-13-196941151
Content-Type: text/x-ruby-script; name="hello.rb"
Content-Transfer-Encoding: 7bit
Content-Disposition: attachment;
	filename="api.rb"

puts "Hello, world!"
gets

--Apple-Mail-13-196941151--
HERE
    assert_equal(true, mail.multipart?)
    assert_equal(1, mail.attachments.length)
  end
end
