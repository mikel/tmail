$:.unshift File.dirname(__FILE__)
require 'test_helper'
require 'tmail/address'

# This file is here purely to all me to test just one
# failing address without having to run the entire
# test_address.rb file.  This is just easier when
# using the debugger and RACC debug file

# All tests in here should ALSO appear in the test_address.rb
# file.  This is a temporary spot to put the address or parser
# test you need to debug.

class TestAddress < Test::Unit::TestCase

  def test_s_new
    a = TMail::Address.new(%w(aamine), %w(loveruby net))
    assert_instance_of TMail::Address, a
    assert_nil a.phrase
    assert_equal [], a.routes
    assert_equal 'aamine@loveruby.net', a.spec
  end

  def test_local
    [ [ ['aamine'],        'aamine'        ],
      [ ['Minero Aoki'],   '"Minero Aoki"' ],
      [ ['!@#$%^&*()'],    '"!@#$%^&*()"'  ],
      [ ['a','b','c'],     'a.b.c'         ]

    ].each_with_index do |(words, ok), idx|
      a = TMail::Address.new(words, nil)
      assert_equal ok, a.local, "case #{idx+1}: #{ok.inspect}"
    end
  end

  def test_domain
    [ [ ['loveruby','net'],        'loveruby.net'    ],
      [ ['love ruby','net'],       '"love ruby".net' ],
      [ ['!@#$%^&*()'],            '"!@#$%^&*()"'    ],
      [ ['[192.168.1.1]'],         '[192.168.1.1]'   ]

    ].each_with_index do |(words, ok), idx|
      a = TMail::Address.new(%w(test), words)
      assert_equal ok, a.domain, "case #{idx+1}: #{ok.inspect}"
    end
  end

  def test_EQUAL   # ==
    a = TMail::Address.new(%w(aamine), %w(loveruby net))
    assert_equal a, a

    b = TMail::Address.new(%w(aamine), %w(loveruby net))
    b.phrase = 'Minero Aoki'
    assert_equal a, b

    b.routes.push 'a'
    assert_equal a, b
  end

  def test_hash
    a = TMail::Address.new(%w(aamine), %w(loveruby net))
    assert_equal a.hash, a.hash

    b = TMail::Address.new(%w(aamine), %w(loveruby net))
    b.phrase = 'Minero Aoki'
    assert_equal a.hash, b.hash

    b.routes.push 'a'
    assert_equal a.hash, b.hash
  end

  def test_dup
    a = TMail::Address.new(%w(aamine), %w(loveruby net))
    a.phrase = 'Minero Aoki'
    a.routes.push 'someroute'

    b = a.dup
    assert_equal a, b

    b.routes.push 'anyroute'
    assert_equal a, b

    b.phrase = 'AOKI, Minero'
    assert_equal a, b
  end

  def test_inspect
    a = TMail::Address.new(%w(aamine), %w(loveruby net))
    a.inspect
    a.phrase = 'Minero Aoki'
    a.inspect
    a.routes.push 'a'
    a.routes.push 'b'
    a.inspect
  end

  
  def validate_case__address( str, ok )
    a = TMail::Address.parse(str)
    assert_equal ok[:display_name], a.phrase, str.inspect + " (phrase)\n"
    assert_equal ok[:address],      a.spec,   str.inspect + " (spec)\n"
    assert_equal ok[:local],        a.local,  str.inspect + " (local)\n"
    assert_equal ok[:domain],       a.domain, str.inspect + " (domain)\n"
  # assert_equal ok[:format],       a.to_s,   str.inspect + " (to_s)\n"
  end

end
