module Test
  module Unit
    class TestCase
      def kcode(code)
        begin
          $KCODE = code
          yield
        ensure
          $KCODE = 'NONE'
        end
      end
    end
  end
end
