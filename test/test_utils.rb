require 'tmail'
require 'tmail/utils'
require 'test/unit'

class UtilsTester < Test::Unit::TestCase

  def test_new_boundary
    a = new_boundary()
    b = new_boundary()
    c = new_boundary()
    assert_instance_of String, a
    assert_instance_of String, b
    assert_instance_of String, c
    assert(a != b)
    assert(b != c)
    assert(c != a)
  end
end
