# typed: true
# frozen_string_literal: true

require "test_helper"

class RBI
  class InflateTest < Minitest::Test
    include TestHelper

    def test_inflate_when_all_scopes_are_known
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

    def test_inflate
      rbi = <<~RBI
        module A::B::C::D
          def foo; end
        end

        A::B::C::D::E = 10;
      RBI
      errors = assert_inflate_equal(<<~EXP, rbi)
        module A
          module B
            module C
              module D
                def foo; end
                E = 10
              end
            end
          end
        end
      EXP
      assert_equal([
        "Can't infer scope type for `A` (used `module` instead)",
        "Can't infer scope type for `B` (used `module` instead)",
        "Can't infer scope type for `C` (used `module` instead)",
        "Can't infer scope type for `A` (used `module` instead)",
        "Can't infer scope type for `B` (used `module` instead)",
        "Can't infer scope type for `C` (used `module` instead)",
      ], errors.map(&:message))
    end

    private

    def assert_inflate_equal(exp, rbi)
      inflated, errors = parse(rbi).inflate
      assert_equal(exp, inflated.to_rbi)
      errors
    end
  end
end
