# typed: true
# frozen_string_literal: true

require "test_helper"

class RBI
  module Parser
    class Whitequark
      module TestHelper
        extend T::Sig

        sig { params(string: String).returns(T.nilable(String)) }
        def parse_string(string)
          RBI.from_string(string)&.to_rbi
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

      class NameVisitorTest < Minitest::Test
        include TestHelper
        extend T::Sig

        sig { params(string: String).returns(T.nilable(String)) }
        def parse_string(string)
          NameVisitor.visit(::Parser::CurrentRuby.parse(string))
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
          ExpBuilder.visit(::Parser::CurrentRuby.parse(string))
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

        def test_parse_singleton_class
          rbi = <<~RBI
            class Foo
              class << self
                sig { void }
                def foo; end
              end
            end
          RBI
          assert_rbi_same(rbi)
        end

        def test_parse_locations
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
          assert_equal(<<~EXP, RBI.from_string(rbi)&.to_rbi(show_locs: true))
            # -:1:0-16:3
            class Foo
              # -:2:2-2:14
              sig { void }
              def foo; end # -:3:2-3:14

              # -:5:2-5:25
              sig { returns(String) }
              def foo; end # -:6:2-6:14

              # -:8:2-8:85
              sig { params(a: T.untyped, b: T::Array[String]).returns(T::Hash[String, Integer]) }
              def foo(a, b:); end # -:9:2-9:21

              # -:11:2-11:42
              sig { abstract.params(a: Integer).void }
              def foo(a); end # -:12:2-12:17

              # -:14:2-14:35
              sig { returns(T::Array[String]) }
              attr_reader :a # -:15:2-15:16
            end

            # -:18:0-18:34
            sig { returns(T.nilable(String)) }
            def foo; end # -:19:0-19:12
          EXP
        end
      end
    end
  end
end
