# typed: true
# frozen_string_literal: true

require "test_helper"

class RBI
  class ParserTest < Minitest::Test
    extend T::Sig

    sig { params(string: String).returns(String) }
    def parse_rbi(string)
      RBI.from_string(string).to_rbi
    end

    sig { params(exp: String, string: String).void }
    def assert_parse(exp, string)
      assert_equal(exp, parse_rbi(string))
    end

    sig { params(string: String).void }
    def assert_parse_identical(string)
      assert_equal(string, parse_rbi(string))
    end

    # Tests

    def test_parse_empty
      assert_parse_identical("")
    end

    def test_parse_commands
      assert_parse_identical("# typed: true")
    end

    def test_scopes_nesting
      rbi = <<~RBI
        module M
          module M1
            module M11
              module M111; end
              class M122; end
            end

            module M12; end

            class M13
              module M131; end
            end
          end

          module M2; end
        end
      RBI
      assert_parse_identical(rbi)
    end

    def test_scopes_body
      rbi = <<~RBI
        module I
          interface!
        end

        class C
          abstract!
          sealed!
        end
      RBI
      assert_parse_identical(rbi)
    end

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
      assert_parse(exp, rbi)
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
      assert_parse(exp, rbi)
    end

    def test_parse_methods
      rbi = <<~RBI
        def foo; end

        def self.foo()
        end

        def foo(x, *y, z:); end

        def foo(
          p1,
          p2 = "foo",
          *p3
        ); end

        def foo(
          p1:,
          p2: "foo",
          **p3
        ); end
      RBI
      exp = <<~RBI
        def foo; end
        def self.foo; end
        def foo(x, *y, z:); end
        def foo(p1, p2 = "foo", *p3); end
        def foo(p1:, p2: "foo", **p3); end
      RBI
      assert_parse(exp, rbi)
    end

    def test_parse_consts
      rbi = <<~RBI
        CONST2 = CONST1
        ::CONST2 = CONST1
        C::C::C = C::C::C
        C::C = foo
        ::C::C = foo
      RBI
      assert_parse_identical(rbi)
    end

    def test_parse_calls
      rbi = <<~RBI
        include A
        extend B
        prepend C, D
        mixes_in_class_methods A, B, C
        sealed!
        interface!
        abstract!
        attr_reader :a
        attr_accessor :a, :b
      RBI
      assert_parse_identical(rbi)
    end

    def test_parse_sigs
      rbi = <<~RBI
        class Foo
          sig { void }
          def foo; end

          sig { returns(String) }
          def foo; end

          sig { params(a: T.untyped, b: T::Array[String]).returns(T::Hash[String, Integer]) }
          def foo(a, b:); end

          sig { abstract.params(a: Integer).void }
          def foo(a); end

          sig { returns(String) }
          attr_reader :a
        end

        sig do
          returns(T.nilable(String))
        end
        def foo; end
      RBI
      assert_parse_identical(rbi)
    end

    def test_parse_tstruct
      rbi = <<~RBI
        class Foo < T::Struct
          prop :foo, String
          const :foo, String, default: "foo"

          sig { params(a: T.untyped, b: T::Array[String]).returns(T::Hash[String, Integer]) }
          def foo(a, b:); end

          def foo; end
        end
      RBI
      assert_parse_identical(rbi)
    end
  end
end
