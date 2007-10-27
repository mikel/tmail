$:.unshift File.dirname(__FILE__)
require 'tmail'
require 'kcode'
require 'extctrl'
require 'test/unit'
require 'time'
require 'test_helper'

class TestMail < Test::Unit::TestCase
  include TMail::TextUtils

  def setup
    @mail = TMail::Mail.new
  end

  def lf( str )
    str.gsub(/\n|\r\n|\r/) { "\n" }
  end

  def crlf( str )
    str.gsub(/\n|\r\n|\r/) { "\r\n" }
  end

  def test_MIME
    # FIXME: test more.

    kcode('EUC') {
      mail = TMail::Mail.parse('From: hoge@example.jp (=?iso-2022-jp?B?GyRCJUYlOSVIGyhC?=)')
      assert_not_nil mail['From']
      assert_equal ["\245\306\245\271\245\310"], mail['From'].comments
      assert_equal "From: hoge@example.jp (\245\306\245\271\245\310)\n\n",
                   mail.to_s
      assert_equal "From: hoge@example.jp (\245\306\245\271\245\310)\n\n",
                   mail.decoded
      assert_equal "From: hoge@example.jp (=?iso-2022-jp?B?GyRCJUYlOSVIGyhC?=)\r\n\r\n",
                   mail.encoded
    }
  end

  def test_to_s
    time = Time.parse('Tue, 4 Dec 2001 10:49:58 +0900').strftime("%a,%e %b %Y %H:%M:%S %z")
    str =<<EOS
Date: #{time}
To: Minero Aoki <aamine@loveruby.net>
Subject: This is test message.

This is body.
EOS
    str = crlf(str)
    m = TMail::Mail.parse(str)
    # strip to avoid error by body's line terminator.
    assert_equal lf(str).strip, m.decoded.strip
    assert_equal crlf(str).strip, m.encoded.strip
  end

  def test__empty_return_path
    str = "Return-Path: <>\r\n\r\n"
    assert_equal str, TMail::Mail.parse(str).encoded
  end

  def test_date
    t = Time.now
    @mail.date = t
    assert_equal t.to_i, @mail.date.to_i   # avoid usec comparison
    assert_equal time2str(t), @mail['date'].to_s

    str = "Date: #{time2str(t)}\n\n"
    assert_equal str, TMail::Mail.parse(str).to_s
  end

  def test_strftime
    t = Time.now
    fmt = '%A%a%B%b%c%d%H%I%j%M%m%p%S%U%W%w%X%x%Y%y%Z%%'
    @mail.date = t
    assert_equal t.strftime(fmt), @mail.strftime(fmt)
  end

  def test_to
    addr = 'Minero Aoki <aamine@loveruby.net>'
    @mail.to = addr
    assert_equal 1, @mail['to'].addrs.size
    assert_equal 'aamine@loveruby.net', @mail['to'].addrs[0].spec
    assert_equal 'Minero Aoki', @mail['to'].addrs[0].phrase

    a = @mail.to_addrs
    assert_equal 1, a.size
    assert_equal 'aamine@loveruby.net', a[0].spec
    assert_equal 'Minero Aoki', a[0].phrase

    a = @mail.to
    assert_equal 1, a.size
    assert_equal 'aamine@loveruby.net', a[0]

    addr = TMail::Address.parse('Minero Aoki <aamine@loveruby.net>')
    @mail.to_addrs = addr
    assert_equal 1, @mail['to'].addrs.size
    assert_equal 'aamine@loveruby.net', @mail['to'].addrs[0].spec
    assert_equal 'Minero Aoki', @mail['to'].addrs[0].phrase

    a = @mail.to_addrs
    assert_equal 1, a.size
    assert_equal 'aamine@loveruby.net', a[0].spec
    assert_equal 'Minero Aoki', a[0].phrase

    a = @mail.to
    assert_equal 1, a.size
    assert_equal 'aamine@loveruby.net', a[0]


    @mail.to = ''
    assert_equal nil, @mail.to
    assert_equal 'DEFAULT VALUE', @mail.to('DEFAULT VALUE')

    @mail.to = 'undisclosed-recipients: ;'
    a = @mail.to
    assert_equal nil, @mail.to
    assert_equal 'DEFAULT VALUE', @mail.to('DEFAULT VALUE')


    str = "\"Aoki, Minero\" <aamine@loveruby.net>\n\n"
    @mail.to_addrs = a = TMail::Address.parse(str)
    assert_equal ['aamine@loveruby.net'], @mail.to
    assert_equal [a], @mail.to_addrs
    assert_equal '"Aoki, Minero" <aamine@loveruby.net>', @mail.to_addrs[0].to_s
    assert_equal '"Aoki, Minero" <aamine@loveruby.net>', @mail['to'].to_s
  end

  def test_cc
    addr = 'Minero Aoki <aamine@loveruby.net>'
    @mail.cc = addr
    assert_equal 1, @mail['cc'].addrs.size
    assert_equal 'aamine@loveruby.net', @mail['cc'].addrs[0].spec
    assert_equal 'Minero Aoki', @mail['cc'].addrs[0].phrase

    a = @mail.cc_addrs
    assert_equal 1, a.size
    assert_equal 'aamine@loveruby.net', a[0].spec
    assert_equal 'Minero Aoki', a[0].phrase

    a = @mail.cc
    assert_equal 1, a.size
    assert_equal 'aamine@loveruby.net', a[0]

    addr = TMail::Address.parse('Minero Aoki <aamine@loveruby.net>')
    @mail.cc_addrs = addr
    assert_equal 1, @mail['cc'].addrs.size
    assert_equal 'aamine@loveruby.net', @mail['cc'].addrs[0].spec
    assert_equal 'Minero Aoki', @mail['cc'].addrs[0].phrase

    a = @mail.cc_addrs
    assert_equal 1, a.size
    assert_equal 'aamine@loveruby.net', a[0].spec
    assert_equal 'Minero Aoki', a[0].phrase

    a = @mail.cc
    assert_equal 1, a.size
    assert_equal 'aamine@loveruby.net', a[0]


    @mail.cc = ''
    assert_equal nil, @mail.cc
    assert_equal 'DEFAULT VALUE', @mail.cc('DEFAULT VALUE')

    @mail.cc = 'undisclosed-recipients: ;'
    a = @mail.cc
    assert_equal nil, @mail.cc
    assert_equal 'DEFAULT VALUE', @mail.cc('DEFAULT VALUE')
  end

  def test_bcc
    addr = 'Minero Aoki <aamine@loveruby.net>'
    @mail.bcc = addr
    assert_equal 1, @mail['bcc'].addrs.size
    assert_equal 'aamine@loveruby.net', @mail['bcc'].addrs[0].spec
    assert_equal 'Minero Aoki', @mail['bcc'].addrs[0].phrase

    a = @mail.bcc_addrs
    assert_equal 1, a.size
    assert_equal 'aamine@loveruby.net', a[0].spec
    assert_equal 'Minero Aoki', a[0].phrase

    a = @mail.bcc
    assert_equal 1, a.size
    assert_equal 'aamine@loveruby.net', a[0]

    addr = TMail::Address.parse('Minero Aoki <aamine@loveruby.net>')
    @mail.bcc_addrs = addr
    assert_equal 1, @mail['bcc'].addrs.size
    assert_equal 'aamine@loveruby.net', @mail['bcc'].addrs[0].spec
    assert_equal 'Minero Aoki', @mail['bcc'].addrs[0].phrase

    a = @mail.bcc_addrs
    assert_equal 1, a.size
    assert_equal 'aamine@loveruby.net', a[0].spec
    assert_equal 'Minero Aoki', a[0].phrase

    a = @mail.bcc
    assert_equal 1, a.size
    assert_equal 'aamine@loveruby.net', a[0]


    @mail.bcc = ''
    assert_equal nil, @mail.bcc
    assert_equal 'DEFAULT VALUE', @mail.bcc('DEFAULT VALUE')

    @mail.bcc = 'undisclosed-recipients: ;'
    a = @mail.bcc
    assert_equal nil, @mail.bcc
    assert_equal 'DEFAULT VALUE', @mail.bcc('DEFAULT VALUE')
  end

  def test_from
    addr = 'Minero Aoki <aamine@loveruby.net>'
    @mail.from = addr
    assert_equal 1, @mail['from'].addrs.size
    assert_equal 'aamine@loveruby.net', @mail['from'].addrs[0].spec
    assert_equal 'Minero Aoki', @mail['from'].addrs[0].phrase

    a = @mail.from_addrs
    assert_equal 1, a.size
    assert_equal 'aamine@loveruby.net', a[0].spec
    assert_equal 'Minero Aoki', a[0].phrase

    a = @mail.from
    assert_equal 1, a.size
    assert_equal 'aamine@loveruby.net', a[0]

    addr = TMail::Address.parse('Minero Aoki <aamine@loveruby.net>')
    @mail.from_addrs = addr
    assert_equal 1, @mail['from'].addrs.size
    assert_equal 'aamine@loveruby.net', @mail['from'].addrs[0].spec
    assert_equal 'Minero Aoki', @mail['from'].addrs[0].phrase

    a = @mail.from_addrs
    assert_equal 1, a.size
    assert_equal 'aamine@loveruby.net', a[0].spec
    assert_equal 'Minero Aoki', a[0].phrase

    a = @mail.from
    assert_equal 1, a.size
    assert_equal 'aamine@loveruby.net', a[0]


    @mail.from = ''
    assert_equal nil, @mail.from
    assert_equal 'DEFAULT VALUE', @mail.from('DEFAULT VALUE')

    @mail.from = 'undisclosed-recipients: ;'
    a = @mail.from
    assert_equal nil, @mail.from
    assert_equal 'DEFAULT VALUE', @mail.from('DEFAULT VALUE')
  end

  def test_reply_to
    addr = 'Minero Aoki <aamine@loveruby.net>'
    @mail.reply_to = addr
    assert_equal 1, @mail['reply-to'].addrs.size
    assert_equal 'aamine@loveruby.net', @mail['reply-to'].addrs[0].spec
    assert_equal 'Minero Aoki', @mail['reply-to'].addrs[0].phrase

    a = @mail.reply_to_addrs
    assert_equal 1, a.size
    assert_equal 'aamine@loveruby.net', a[0].spec
    assert_equal 'Minero Aoki', a[0].phrase

    a = @mail.reply_to
    assert_equal 1, a.size
    assert_equal 'aamine@loveruby.net', a[0]

    addr = TMail::Address.parse('Minero Aoki <aamine@loveruby.net>')
    @mail.reply_to_addrs = addr
    assert_equal 1, @mail['reply-to'].addrs.size
    assert_equal 'aamine@loveruby.net', @mail['reply-to'].addrs[0].spec
    assert_equal 'Minero Aoki', @mail['reply-to'].addrs[0].phrase

    a = @mail.reply_to_addrs
    assert_equal 1, a.size
    assert_equal 'aamine@loveruby.net', a[0].spec
    assert_equal 'Minero Aoki', a[0].phrase

    a = @mail.reply_to
    assert_equal 1, a.size
    assert_equal 'aamine@loveruby.net', a[0]


    @mail.reply_to = ''
    assert_equal nil, @mail.reply_to
    assert_equal 'DEFAULT VALUE', @mail.reply_to('DEFAULT VALUE')

    @mail.reply_to = 'undisclosed-recipients: ;'
    a = @mail.reply_to
    assert_equal nil, @mail.reply_to
    assert_equal 'DEFAULT VALUE', @mail.reply_to('DEFAULT VALUE')
  end

  def do_test_address_attr( name )
    addr = 'Minero Aoki <aamine@loveruby.net>'
    @mail.__send__( name + '=', addr )
    a = @mail.__send__( name + '_addrs' )
    assert_equal 1, a.size
    assert_equal 'aamine@loveruby.net', a[0].spec
    assert_equal 'Minero Aoki', a[0].phrase

    a = @mail.__send__( name )
    assert_equal 1, a.size
    assert_equal 'aamine@loveruby.net', a[0]
  end

  def test_subject
    s = 'This is test subject!'
    @mail.subject = s
    assert_equal s, @mail.subject
    assert_equal s, @mail['subject'].to_s
  end

  def test_unquote_quoted_printable_subject
    msg = <<EOF
From: me@example.com
Subject: =?utf-8?Q?testing_testing_=D6=A4?=
Content-Type: text/plain; charset=iso-8859-1

The body
EOF
    mail = TMail::Mail.parse(msg)
    assert_equal "testing testing \326\244", mail.subject
    assert_equal "=?utf-8?Q?testing_testing_=D6=A4?=", mail.quoted_subject
  end

  def test_unquote_7bit_subject
    msg = <<EOF
From: me@example.com
Subject: this == working?
Content-Type: text/plain; charset=iso-8859-1

The body
EOF
    mail = TMail::Mail.parse(msg)
    assert_equal "this == working?", mail.subject
    assert_equal "this == working?", mail.quoted_subject
  end

  def test_unquote_7bit_body
    msg = <<EOF
From: me@example.com
Subject: subject
Content-Type: text/plain; charset=iso-8859-1
Content-Transfer-Encoding: 7bit

The=3Dbody
EOF
    mail = TMail::Mail.parse(msg)
    assert_equal "The=3Dbody", mail.body.strip
    assert_equal "The=3Dbody", mail.quoted_body.strip
  end

  def test_unquote_quoted_printable_body
    msg = <<EOF
From: me@example.com
Subject: subject
Content-Type: text/plain; charset=iso-8859-1
Content-Transfer-Encoding: quoted-printable

The=3Dbody
EOF
    mail = TMail::Mail.parse(msg)
    assert_equal "The=body", mail.body.strip
    assert_equal "The=3Dbody", mail.quoted_body.strip
  end

  def test_unquote_base64_body
    msg = <<EOF
From: me@example.com
Subject: subject
Content-Type: text/plain; charset=iso-8859-1
Content-Transfer-Encoding: base64

VGhlIGJvZHk=
EOF
    mail = TMail::Mail.parse(msg)
    assert_equal "The body", mail.body.strip
    assert_equal "VGhlIGJvZHk=", mail.quoted_body.strip
  end

  def test_message_id
    assert_nil @mail.message_id
    assert_equal 1, @mail.message_id(1)

    m = '<very.unique.identity@fully.quorified.domain.name>'
    @mail.message_id = m
    assert_equal m, @mail.message_id
  end

  def test_in_reply_to
    i = '<very.unique.identity@fully.quorified.domain.name>'
    @mail.in_reply_to = i
    a = @mail.in_reply_to
    assert_equal a.size, 1
    assert_equal i, a[0]

    @mail.in_reply_to = [i]
    a = @mail.in_reply_to
    assert_equal a.size, 1
    assert_equal i, a[0]
  end

  def test_references
    i = '<very.unique.identity@fully.quorified.domain.name>'
    @mail.references = i
    a = @mail.references
    assert_equal a.size, 1
    assert_equal i, a[0]
    
    @mail.references = [i]
    a = @mail.references
    assert_equal a.size, 1
    assert_equal i, a[0]
  end

  def test_mime_version
    assert_nil @mail.mime_version
    assert_equal 1, @mail.mime_version(1)

    %w( 1.0 999.999 ).each do |v|
      @mail.mime_version = v
      assert_equal v, @mail.mime_version
    end
  end

  def test_content_type
    [ 'text/plain', 'application/binary', 'multipart/mixed' ].each do |t|
      @mail.content_type = t
      assert_equal t, @mail.content_type
      assert_equal t.split('/',2)[0], @mail.main_type
      assert_equal t.split('/',2)[1], @mail.sub_type
    end

    @mail.content_type = 'text/plain; charset=iso-2022-jp'
    @mail.content_type = 'application/postscript'

    assert_raises(ArgumentError) {
      @mail.content_type = 'text'
    }
  end

  def test_mail_to_s_with_illegal_content_type_boundary_preserves_quotes
    msg = <<EOF
From: mikel@example.com
Subject: Hello
Content-Type: multipart/signed;
	micalg=sha1;
	boundary=Apple-Mail-42-587703407;
	protocol="application/pkcs7-signature"

The body
EOF

    output = <<EOF
From: mikel@example.com
Subject: Hello
Content-Type: multipart/signed; protocol="application/pkcs7-signature"; boundary=Apple-Mail-42-587703407; micalg=sha1

The body
EOF

    mail = TMail::Mail.parse(msg)
    assert_equal(output, mail.to_s)
  end

  def test_mail_to_s_with_filename_preserves_quotes
    msg = <<EOF
From: mikel@example.com
Subject: =?utf-8?Q?testing_testing_=D6=A4?=
Content-Disposition: attachment; filename="README.txt.pif"

The body
EOF
    mail = TMail::Mail.parse(msg)
    assert_equal(msg, mail.to_s)
  end

  def test_charset
    c = 'iso-2022-jp'
    @mail.charset = c
    assert_equal c, @mail.charset
    assert_equal 'text', @mail.main_type
    assert_equal 'plain', @mail.sub_type

    @mail.content_type = 'application/binary'
    @mail.charset = c
    assert_equal c, @mail.charset
  end

  def test_transfer_encoding
    @mail.transfer_encoding = 'base64'
    assert_equal 'base64', @mail.transfer_encoding
    @mail.transfer_encoding = 'BASE64'
    assert_equal 'base64', @mail.transfer_encoding
    @mail.content_transfer_encoding = '7bit'
    assert_equal '7bit', @mail.content_transfer_encoding
    @mail.encoding = 'binary'
    assert_equal 'binary', @mail.encoding
  end

  def test_disposition
    @mail['content-disposition'] = 'attachment; filename="test.rb"'
    assert_equal 'attachment', @mail.disposition
    assert_equal 'attachment', @mail.content_disposition
    assert_equal 'test.rb', @mail.disposition_param('filename')

    @mail.disposition = 'none'
    assert_equal 'none', @mail.disposition
    assert_nil @mail.disposition_param('filename')
    assert_equal 1, @mail.disposition_param('filename', 1)

    src = '=?iso-2022-jp?B?GyRCRnxLXDhsGyhCLnR4dA==?='
    @mail['content-disposition'] = %Q(attachment; filename="#{src}")
    ok = NKF.nkf('-m -e', src)
    kcode('EUC') {
        assert_equal ok, @mail.disposition_param('filename')
    }
  end

  def test_set_disposition
    @mail.set_disposition 'attachment', 'filename'=>'sample.rb'
    assert_equal 'attachment', @mail.disposition
    assert_equal 'sample.rb', @mail.disposition_param('filename')
  end

  def test_receive_attachments
    fixture = File.read(File.dirname(__FILE__) + "/fixtures/raw_email2")
    mail = TMail::Mail.parse(fixture)
    attachment = mail.attachments.last
    assert_equal "smime.p7s", attachment.original_filename
    assert_equal "application/pkcs7-signature", attachment.content_type
  end

  def test_body_with_underscores
    m = TMail::Mail.new
    expected = 'something_with_underscores'
    m.encoding = 'quoted-printable'
    quoted_body = [expected].pack('*M')
    m.body = quoted_body
    assert_equal "something_with_underscores=\n", m.quoted_body
    assert_equal expected, m.body
  end

  def test_nested_attachments_are_recognized_correctly
    fixture = File.read("#{File.dirname(__FILE__)}/fixtures/raw_email_with_nested_attachment")
    mail = TMail::Mail.parse(fixture)
    assert_equal 2, mail.attachments.length
    assert_equal "image/png", mail.attachments.first.content_type
    assert_equal 1902, mail.attachments.first.length
    assert_equal "application/pkcs7-signature", mail.attachments.last.content_type
  end
  
  def test_decode_attachment_without_charset
    fixture = File.read(File.dirname(__FILE__) + "/fixtures/raw_email3")
    mail = TMail::Mail.parse(fixture)
    attachment = mail.attachments.last
    assert_equal 1026, attachment.read.length
  end

  def test_decode_message_without_content_type
    fixture = File.read(File.dirname(__FILE__) + "/fixtures/raw_email4")
    mail = TMail::Mail.parse(fixture)
    assert_nothing_raised { mail.body }
  end

  def test_quoting_of_illegal_boundary_when_doing_mail_to_s
    fixture = File.read(File.dirname(__FILE__) + "/fixtures/raw_email_with_illegal_boundary")
    mail = TMail::Mail.parse(fixture)
    assert_equal(true, mail.multipart?)
    assert_equal('multipart/alternative; boundary="----=_NextPart_000_0093_01C81419.EB75E850"', mail['content-type'].to_s)
  end

  def test_quoted_illegal_boundary_when_doing_mail_to_s
    fixture = File.read(File.dirname(__FILE__) + "/fixtures/raw_email_with_quoted_illegal_boundary")
    mail = TMail::Mail.parse(fixture)
    assert_equal(true, mail.multipart?)
    assert_equal('multipart/alternative; boundary="----=_NextPart_000_0093_01C81419.EB75E850"', mail['content-type'].to_s)
  end

  def test_quoted_illegal_boundary_with_multipart_mixed_when_doing_mail_to_s
    fixture = File.read(File.dirname(__FILE__) + "/fixtures/raw_email_with_multipart_mixed_quoted_boundary")
    mail = TMail::Mail.parse(fixture)
    assert_equal(true, mail.multipart?)
    assert_equal('multipart/mixed; boundary="----=_Part_2192_32400445.1115745999735"', mail['content-type'].to_s)
  end

end
