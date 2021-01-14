# typed: true
# frozen_string_literal: true

require "test_helper"

class RBI
  module Parser
    class Sorbet
      class ParserTest < Minitest::Test
        extend T::Sig

        def test_parse_empty
          assert_rbi_same("")
        end

        # def test_scopes_nesting
          # rbi = <<~RBI
            # module M
              # module M1
                # module M11
                  # module M111; end
                  # class M122; end
                # end
#
                # module M12; end
#
                # class M13
                  # module M131; end
                # end
              # end
#
              # module M2; end
            # end
          # RBI
          # assert_rbi_same(rbi)
        # end
#
        # def test_scopes_body
          # rbi = <<~RBI
            # module I
              # interface!
            # end
#
            # class C
              # abstract!
              # sealed!
            # end
          # RBI
          # assert_rbi_same(rbi)
        # end
#
        def test_parse_modules
          rbi = <<~RBI
            module A; end

            module B
            end

            module A::B::C; end

            module A::B
            end
          RBI
          exp = <<~RBI
            module A; end
            module B; end
            module A::B::C; end
            module A::B; end
          RBI
          assert_rbi_equals(exp, rbi)
        end

        def test_parse_classes
          rbi = <<~RBI
            class A; end

            class B < A
            end

            class A::B::C < A; end

            class A::B
            end
          RBI
          exp = <<~RBI
            class A; end
            class B < A; end
            class A::B::C < A; end
            class A::B; end
          RBI
          assert_rbi_equals(exp, rbi)
        end
#
        # def test_parse_consts
          # rbi = <<~RBI
            # CONST2 = CONST1
            # ::CONST2 = CONST1
            # C::C::C = C::C::C
            # C::C = foo
            # ::C::C = foo
          # RBI
          # assert_rbi_same(rbi)
        # end
#
        # def test_parse_methods
          # rbi = <<~RBI
            # def foo; end
            # def foo(x, *y, z:); end
            # def foo(p1, p2 = "foo", *p3); end
            # def foo(p1:, p2: "foo", **p3); end
          # RBI
          # assert_rbi_same(rbi)
        # end
#
        # def test_parse_calls
          # rbi = <<~RBI
            # include A
            # extend B
            # prepend C, D
            # mixes_in_class_methods A, B, C
            # sealed!
            # interface!
            # abstract!
            # attr_reader :a
            # attr_accessor :a, :b
          # RBI
          # assert_rbi_same(rbi)
        # end
#
        # def test_parse_sigs
          # rbi = <<~RBI
            # class Foo
              # sig { void }
              # def foo; end
#
              # sig { returns(String) }
              # def foo; end
#
              # sig { params(a: T.untyped, b: T::Array[String]).returns(T::Hash[String, Integer]) }
              # def foo(a, b:); end
#
              # sig { abstract.params(a: Integer).void }
              # def foo(a); end
#
              # sig { returns(T::Array[String]) }
              # attr_reader :a
            # end
#
            # sig { returns(T.nilable(String)) }
            # def foo; end
          # RBI
          # assert_rbi_same(rbi)
        # end

        private

        sig { params(string: String).returns(T.nilable(String)) }
        def parse_string(string)
          RBI.from_string(string, parser: Sorbet.new)&.to_rbi
        end

        sig { params(exp: String, string: String).void }
        def assert_rbi_equals(exp, string)
          T.unsafe(self).assert_equal(exp, parse_string(string))
        end

        sig { params(string: String).void }
        def assert_rbi_same(string)
          assert_rbi_equals(string, string)
        end
      end
    end
  end
end
