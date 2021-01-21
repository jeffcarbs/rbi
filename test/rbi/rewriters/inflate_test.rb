# typed: true
# frozen_string_literal: true

require "test_helper"

class RBI
  class InflateTest < Minitest::Test
    include TestHelper

    def test_inflate
      rbi = <<~RBI
        module A; end

        module A::B
          def foo; end
        end

        class A::B::C; end
        A::B::C::D = 10;
      RBI
      assert_inflate_equal(<<~EXP, rbi)
        module A
          module B
            def foo; end

            class C
              D = 10
            end
          end
        end
      EXP
    end

    # TODO error don't exist def for module/class

    private

    def assert_inflate_equal(exp, rbi)
      assert_equal(exp, parse(rbi).inflate.to_rbi)
    end
  end
end
