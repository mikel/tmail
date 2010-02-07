# -*- encoding: utf-8 -*-
#
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
  
  def test_recursive_multipart_processing
    fixture = File.read(File.dirname(__FILE__) + "/fixtures/raw_email7")
    mail = TMail::Mail.parse(fixture)
    assert_equal "This is the first part.\n\nAttachment: test.rb\nAttachment: test.pdf\n\n\nAttachment: smime.p7s\n", mail.body
  end

  def test_decode_encoded_attachment_filename
    fixture = File.read(File.dirname(__FILE__) + "/fixtures/raw_email8")
    mail = TMail::Mail.parse(fixture)
    attachment = mail.attachments.last
    expected = "01 Quien Te Dij\212at. Pitbull.mp3"
    expected.force_encoding(Encoding::ASCII_8BIT) if expected.respond_to?(:force_encoding)
    assert_equal expected, attachment.original_filename
  end

  def test_attachment_with_quoted_filename
    fixture = File.read(File.dirname(__FILE__) + "/fixtures/raw_email_with_quoted_attachment_filename")
    mail = TMail::Mail.parse(fixture)
    attachment = mail.attachments.last
    str = "Eelanalüüsi päring.jpg"
    assert_equal str, attachment.original_filename
  end

  def test_assigning_attachment_crashing_due_to_missing_boundary
    mail = TMail::Mail.new  
    mail.mime_version = '1.0'
    mail.set_content_type("multipart", "mixed")
    
    mailpart=TMail::Mail.new
    mailpart.set_content_type("application", "octet-stream")
    mailpart['Content-Disposition'] = "attachment; filename=mailbox.zip"

    assert_nothing_raised { mail.parts.push(mailpart) }
  end
  
  def test_only_has_attachment
    fixture = File.read(File.dirname(__FILE__) + "/fixtures/raw_email_only_attachment")
    mail = TMail::Mail.parse(fixture)
    assert_equal(1, mail.attachments.length)
  end

  def test_content_nil_returned_if_name_of_attachment_type_unquoted
    fixture = File.read(File.dirname(__FILE__) + "/fixtures/unquoted_filename_in_attachment")
    mail = TMail::Mail.parse(fixture)
    assert_equal("image/png", mail.attachments.first.content_type)
  end

  def test_unquoted_apple_mail_content_type
    fixture = File.read(File.dirname(__FILE__) + "/fixtures/apple_unquoted_content_type")
    mail = TMail::Mail.parse(fixture)
    assert_equal("application/pdf", mail.attachments.first.content_type)
  end
  
  # TMail::Mail.has_attachments? & TMail::Mail.attachments
  # http://rubyforge.org/tracker/index.php?func=detail&aid=23099&group_id=4512&atid=17370
  def test_the_only_part_is_a_word_document
    mail = load_fixture('the_only_part_is_a_word_document.txt')

    assert_equal('application/msword', mail.content_type)
    assert !mail.multipart?, 'The mail should not be multipart'
    assert mail.attachment?(mail), 'The mail should be considered has an attachment'

    # The original method TMail::Mail.has_attachments? returns false
    assert mail.has_attachments?, 'PATCH: TMail should consider that this email has an attachment'

    # The original method TMail::Mail.attachments returns nil
    assert_not_nil mail.attachments, 'PATCH: TMail should return the attachment'
    assert_equal 1, mail.attachments.size, 'PATCH: TMail should detect one attachment'
    assert_instance_of TMail::Attachment, mail.attachments.first, 'The first attachment found should be an instance of TMail::Attachment'
  end

  # new method TMail::Mail.inline_attachment?
  def test_inline_attachment_should_detect_inline_attachments
    mail = load_fixture('inline_attachment.txt')

    assert !mail.inline_attachment?(mail.parts[0]), 'The first part is an empty text'
    assert mail.inline_attachment?(mail.parts[1]), 'The second part is an inline attachment'

    mail = load_fixture('the_only_part_is_a_word_document.txt')
    assert !mail.inline_attachment?(mail), 'The first and only part is an normal attachment'
  end

  # new method TMail::Mail.text_content_type?
  def test_text_content_type?
    mail = load_fixture('inline_attachment.txt')

    assert mail.parts[0].text_content_type?, 'The first part of inline_attachment.txt is a text'
    assert !mail.parts[1].text_content_type?, 'The second part of inline_attachment.txt is not a text'
  end

protected

  def load_fixture(name)
    TMail::Mail.load(File.join('test', 'fixtures', name))
  end

end
