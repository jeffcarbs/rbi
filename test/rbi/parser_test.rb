# typed: true
# frozen_string_literal: true

require "test_helper"

class RBI
  module ParserTestHelper
    extend T::Sig

    sig { params(string: String).returns(T.nilable(String)) }
    def parse_string(string)
      nil
    end

    private

    sig { params(string: String).returns(T.nilable(AST::Node)) }
    def parse_internal(string)
      Parser.parse_string(string)
    end

    sig { params(exp: String, string: String).void }
    def assert_parse(exp, string)
      T.unsafe(self).assert_equal(exp, parse_string(string))
    end

    sig { params(string: String).void }
    def assert_identical(string)
      assert_parse(string, string)
    end
  end

  class ParserTest < Minitest::Test
    extend T::Sig

    sig { params(string: String).returns(T.nilable(String)) }
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

          sig { returns(T::Array[String]) }
          attr_reader :a
        end

        sig { returns(T.nilable(String)) }
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

  class NameVisitorTest < Minitest::Test
    extend T::Sig
    include ParserTestHelper

    sig { params(string: String).returns(T.nilable(String)) }
    def parse_string(string)
      NameVisitor.visit(parse_internal(string))
    end

    # Tests

    def test_parse_error
      assert_nil(parse_string(""))
      assert_nil(parse_string(";"))
      assert_nil(parse_string("10"))
      assert_nil(parse_string("-10"))
    end

    def test_parse_names
      assert_identical("_")
      assert_identical("a")
      assert_identical("A")
      assert_identical("foo")
      assert_identical("Foo")
      assert_identical("foo10")
      assert_identical("Foo10")
      assert_identical("_foo")
      assert_identical("_Foo")
    end

    def test_parse_qnames
      assert_identical("_::_")
      assert_identical("a::a")
      assert_identical("A::A")
      assert_identical("foo::foo")
      assert_identical("Foo::Foo")
      assert_identical("foo10::foo10")
      assert_identical("Foo10::Foo10")
      assert_identical("_foo::_foo")
      assert_identical("_Foo::_Foo")
      assert_identical("_::a::A::Foo::foo::_foo::_Foo10")
      assert_identical("::A")
      assert_identical("::A::Foo::FOO")
      assert_identical("::Foo::a")
      assert_identical("::Foo::foo")
      assert_parse("::Foo::foo::bar", "::Foo::foo.bar")
    end

    def test_parse_only_names
      assert_parse("Foo", "Foo[A, B, C]")
      assert_parse("Foo::Bar", "Foo::Bar[A, B, C]")
      assert_parse("Foo", "Foo(A, B, C)")
      assert_parse("Foo::Bar", "Foo::Bar(A, B, C)")
      assert_parse("Foo::bar", "Foo.bar(A, B, C)")
      assert_parse("Foo::Bar::bar", "Foo::Bar.bar(A, B, C)")
      assert_parse("F", "F = 10")
      assert_parse("FOO", "FOO = FOO")
      assert_parse("F::F::F", "F::F::F = FOO")
      assert_parse("::Foo", "::Foo = FOO")
    end
  end

  class ExpVisitorTest < Minitest::Test
    extend T::Sig
    include ParserTestHelper

    sig { params(string: String).returns(T.nilable(String)) }
    def parse_string(string)
      ExpBuilder.parse(string)
    end

    # Tests

    def test_parse_error
      assert_nil(parse_string(""))
      assert_nil(parse_string(";"))
    end

    def test_parse_literals
      assert_identical("0")
      assert_identical("\"foo\"")
      assert_identical("nil")
      assert_identical("-10")
      assert_parse("10.*(10)", "10 * 10")
      assert_parse("\"foo\"", "'foo'")
    end

    def test_parse_names
      assert_identical("_")
      assert_identical("a")
      assert_identical("A")
      assert_identical("foo")
      assert_identical("Foo")
      assert_identical("foo10")
      assert_identical("Foo10")
      assert_identical("_foo")
      assert_identical("_Foo")
    end

    def test_parse_qnames
      assert_identical("A::A")
      assert_identical("Foo::Foo")
      assert_identical("Foo10::Foo10")
    end

    def test_parse_qsends
      assert_parse("_._", "_::_")
      assert_parse("a.a", "a::a")
      assert_parse("Foo.foo", "Foo::foo")
      assert_parse("foo.foo", "foo::foo")
      assert_parse("foo10.foo10", "foo10::foo10")
      assert_parse("_foo._foo", "_foo::_foo")
      assert_parse("_Foo._Foo", "_Foo::_Foo")
      assert_parse("_.a::A::Foo.foo._foo._Foo10", "_::a::A::Foo::foo::_foo::_Foo10")
    end

    def test_parse_indexes
      assert_identical("Foo[A, B, C]")
      assert_identical("Foo::Bar[A, B, C]")
      assert_identical("Foo(A, B, C)")
      assert_identical("Foo.Bar(A, B, C)")
      assert_identical("Foo.bar(A, B, C)")
      assert_identical("Foo::Bar.bar(A, B, C)")
    end

    def test_parse_cbase
      assert_identical("::A")
      assert_identical("::A::Foo::FOO")
      assert_identical("::Foo.a")
      assert_identical("::Foo.foo.bar")
      assert_identical("::Foo.foo(A, B, C)")
      assert_parse("::Foo.a", "::Foo::a")
      assert_parse("::Foo.foo.bar(A, B, C)", "::Foo::foo.bar(A, B, C)")
    end
  end

  class SigBuilderTest < Minitest::Test
    extend T::Sig

    sig { params(string: String).returns(T.nilable(String)) }
    def parse_sig(string)
      SigBuilder.parse(string)&.to_rbi
    end

    sig { params(exp: String, string: String).void }
    def assert_parse(exp, string)
      assert_equal(exp, parse_sig(string))
    end

    sig { params(string: String).void }
    def assert_parse_identical(string)
      assert_parse(string, string)
    end

    # Tests

    def test_parse_empty
      assert_nil(SigBuilder.parse(""))
    end

    def test_parse_empty_sig
      assert_parse_identical("sig {}\n")
    end
  end
end
