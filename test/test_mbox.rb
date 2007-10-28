require 'tmail/mailbox'
require 'fileutils'
require 'test/unit'

class MailboxTester < Test::Unit::TestCase
  include FileUtils

  MAILBOX = '_mh'
  N = 5

  def setup
    rm_rf MAILBOX
    mkdir MAILBOX
    N.downto(1) do |i|
      File.open( "#{MAILBOX}/#{i}", 'w' ) {|f|
          f.puts 'From: aamine'
          f.puts 'To: aamine@loveruby.net'
          f.puts "Subject: #{i}"
          f.puts ''
          f.puts 'body'
      }
    end
    @n = N

    @ld = TMail::MhMailbox.new( MAILBOX )
  end

  def make_mails_older( diff )
    Dir.entries( MAILBOX ).collect {|n| "#{MAILBOX}/#{n}" }.each do |path|
      if File.file? path then
        t = File.mtime(path) - diff
        File.utime t, t, path
      end
    end
  end

  def teardown
    rm_rf MAILBOX
  end

  def test_s_new
    ld = TMail::MhMailbox.new( MAILBOX )
    assert_instance_of TMail::MhMailbox, ld
  end

  def test_each_port
    dir = File.expand_path(MAILBOX)
    c = 0
    n = 0
    TMail::MhMailbox.new( MAILBOX ).each_port do |port|
      assert_kind_of TMail::FilePort, port
      assert_equal dir, File.dirname(port.filename)
      assert_match(/\A\d+\z/, File.basename(port.filename))
      nn = File.basename(port.filename).to_i
      assert nn > n
      n = nn
      c += 1
    end
    assert_equal N, c
  end

  def test_reverse_each_port
    dir = File.expand_path(MAILBOX)
    c = 0
    n = 100000
    TMail::MhMailbox.new( MAILBOX ).reverse_each_port do |port|
      assert_kind_of TMail::FilePort, port
      assert_equal dir, File.dirname(port.filename)
      assert_match(/\A\d+\z/, File.basename(port.filename))
      nn = File.basename(port.filename).to_i
      assert nn < n
      n = nn
      c += 1
    end
    assert_equal N, c
  end

  def test_new_port
    port = @ld.new_port
    assert_kind_of TMail::FilePort, port
    assert_equal File.expand_path('.') + '/' + MAILBOX,
                 File.dirname(port.filename)
    assert_equal( (N+1).to_s, File.basename(port.filename) )
    
    create port
  end

  def create( port )
    port.wopen {|f|
      f.puts 'From: aamine'
      f.puts 'To: aamine@loveruby.net'
      f.puts "Subject: #{@n + 1}"
      f.puts ''
      f.puts 'body'
    }
    @n += 1
  end

  def test_each_new_port
    make_mails_older 5
        
    c = 0
    @ld.each_new_port do |port|
      assert_kind_of TMail::FilePort, port
      c += 1
    end
    assert_equal @n, c

    t = Time.now - 2
    create @ld.new_port
    c = 0
    @ld.each_new_port( t ) do |port|
      assert_kind_of TMail::FilePort, port
      c += 1
    end
    assert_equal 1, c

    make_mails_older 5
    c = 0
    @ld.each_new_port do |port|
      assert_kind_of TMail::FilePort, port
      c += 1
    end
    assert_equal 0, c
  end
end
