# typed: true
# frozen_string_literal: true

require "test_helper"

class RBI
  class NameVisitorTest < Minitest::Test
    include TestHelper
    extend T::Sig

    sig { params(string: String).returns(T.nilable(String)) }
    def parse_string(string)
      node = Parser.parse_string(string)
      NameVisitor.visit(node)
    end

    def test_parse_error
      assert_nil(parse_string(""))
      assert_nil(parse_string(";"))
      assert_nil(parse_string("10"))
      assert_nil(parse_string("-10"))
    end

    def test_parse_names
      assert_rbi_same("_")
      assert_rbi_same("a")
      assert_rbi_same("A")
      assert_rbi_same("foo")
      assert_rbi_same("Foo")
      assert_rbi_same("foo10")
      assert_rbi_same("Foo10")
      assert_rbi_same("_foo")
      assert_rbi_same("_Foo")
    end

    def test_parse_qnames
      assert_rbi_same("_::_")
      assert_rbi_same("a::a")
      assert_rbi_same("A::A")
      assert_rbi_same("foo::foo")
      assert_rbi_same("Foo::Foo")
      assert_rbi_same("foo10::foo10")
      assert_rbi_same("Foo10::Foo10")
      assert_rbi_same("_foo::_foo")
      assert_rbi_same("_Foo::_Foo")
      assert_rbi_same("_::a::A::Foo::foo::_foo::_Foo10")
      assert_rbi_same("::A")
      assert_rbi_same("::A::Foo::FOO")
      assert_rbi_same("::Foo::a")
      assert_rbi_same("::Foo::foo")
      assert_rbi_equals("::Foo::foo::bar", "::Foo::foo.bar")
    end

    def test_parse_only_names
      assert_rbi_equals("Foo", "Foo[A, B, C]")
      assert_rbi_equals("Foo::Bar", "Foo::Bar[A, B, C]")
      assert_rbi_equals("Foo", "Foo(A, B, C)")
      assert_rbi_equals("Foo::Bar", "Foo::Bar(A, B, C)")
      assert_rbi_equals("Foo::bar", "Foo.bar(A, B, C)")
      assert_rbi_equals("Foo::Bar::bar", "Foo::Bar.bar(A, B, C)")
      assert_rbi_equals("F", "F = 10")
      assert_rbi_equals("FOO", "FOO = FOO")
      assert_rbi_equals("F::F::F", "F::F::F = FOO")
      assert_rbi_equals("::Foo", "::Foo = FOO")
    end
  end

  class ExpVisitorTest < Minitest::Test
    include TestHelper
    extend T::Sig

    sig { params(string: String).returns(T.nilable(String)) }
    def parse_string(string)
      ExpBuilder.visit(Parser.parse_string(string))
    end

    def test_parse_error
      assert_nil(parse_string(""))
      assert_nil(parse_string(";"))
    end

    def test_parse_literals
      assert_rbi_same("0")
      assert_rbi_same("\"foo\"")
      assert_rbi_same("nil")
      assert_rbi_same("-10")
      assert_rbi_equals("10.*(10)", "10 * 10")
      assert_rbi_equals("\"foo\"", "'foo'")
    end

    def test_parse_names
      assert_rbi_same("_")
      assert_rbi_same("a")
      assert_rbi_same("A")
      assert_rbi_same("foo")
      assert_rbi_same("Foo")
      assert_rbi_same("foo10")
      assert_rbi_same("Foo10")
      assert_rbi_same("_foo")
      assert_rbi_same("_Foo")
    end

    def test_parse_qnames
      assert_rbi_same("A::A")
      assert_rbi_same("Foo::Foo")
      assert_rbi_same("Foo10::Foo10")
      assert_rbi_same("::A")
      assert_rbi_same("::A::Foo::FOO")
    end

    def test_parse_qsends
      assert_rbi_same("::Foo.a")
      assert_rbi_same("::Foo.foo.bar")
      assert_rbi_same("::Foo.foo(A, B, C)")
      assert_rbi_same("Foo[A, B, C]")
      assert_rbi_same("Foo::Bar[A, B, C]")
      assert_rbi_same("Foo(A, B, C)")
      assert_rbi_same("Foo.Bar(A, B, C)")
      assert_rbi_same("Foo.bar(A, B, C)")
      assert_rbi_same("Foo::Bar.bar(A, B, C)")
      assert_rbi_equals("_._", "_::_")
      assert_rbi_equals("a.a", "a::a")
      assert_rbi_equals("Foo.foo", "Foo::foo")
      assert_rbi_equals("foo.foo", "foo::foo")
      assert_rbi_equals("foo10.foo10", "foo10::foo10")
      assert_rbi_equals("_foo._foo", "_foo::_foo")
      assert_rbi_equals("_Foo._Foo", "_Foo::_Foo")
      assert_rbi_equals("_.a::A::Foo.foo._foo._Foo10", "_::a::A::Foo::foo::_foo::_Foo10")
      assert_rbi_equals("::Foo.a", "::Foo::a")
      assert_rbi_equals("::Foo.foo.bar(A, B, C)", "::Foo::foo.bar(A, B, C)")
    end
  end

  class SigBuilderTest < Minitest::Test
    include TestHelper
    extend T::Sig

    sig { params(string: String).returns(T.nilable(String)) }
    def parse_string(string)
      SigBuilder.parse(string)&.to_rbi
    end

    def test_parse_empty
      assert_nil(parse_string(""))
    end

    def test_parse_empty_sig
      assert_rbi_same("sig {}\n")
    end
  end

  class ParserTest < Minitest::Test
    include TestHelper
    extend T::Sig

    def test_parse_empty
      assert_rbi_same("")
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
      assert_rbi_same(rbi)
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
      assert_rbi_same(rbi)
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

    def test_parse_consts
      rbi = <<~RBI
        CONST2 = CONST1
        ::CONST2 = CONST1
        C::C::C = C::C::C
        C::C = foo
        ::C::C = foo
      RBI
      assert_rbi_same(rbi)
    end

    def test_parse_methods
      rbi = <<~RBI
        def foo; end
        def foo(x, *y, z:); end
        def foo(p1, p2 = "foo", *p3); end
        def foo(p1:, p2: "foo", **p3); end
      RBI
      assert_rbi_same(rbi)
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
      assert_rbi_same(rbi)
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
      assert_rbi_same(rbi)
    end
  end
end
