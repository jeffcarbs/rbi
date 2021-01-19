# typed: true
# frozen_string_literal: true

require "test_helper"

class RBI
  class WhitequarkTest < Minitest::Test
    include TestHelper

    # Misc

    def test_parse_empty
      assert_rbi_same("")
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

    def test_parse_empty_comment
      assert_rbi_equal("", "# typed: true")
    end

    def test_parse_comments
      rbi = <<~RBI
        # typed: true

        # A1
        class A # A2

          # B1

          # B2
          class B
            class C
              # C1
              extend T::Sig # C2

              # foo1

              # foo2
              def foo; end # foo3
            end

            #
            ##
            # bar1

            def bar; end # bar2
          end

          def baz # baz1
            # baz2
          end # baz3
        end # A3

        # main
        def main; end
      RBI
      exp = <<~RBI
        # typed: true
        # A1
        # A3
        class A
          # B1
          # B2
          class B
            class C
              # C1
              extend T::Sig
              # foo1
              # foo2
              # foo3
              def foo; end
            end

            #
            ##
            # bar1
            # bar2
            def bar; end
          end

          # baz1
          # baz2
          # baz3
          def baz; end
        end

        # main
        def main; end
      RBI
      assert_rbi_equal(exp, rbi)
    end

    # Scopes

    def test_scopes_nesting
      rbi = <<~RBI
        module M
          module M1
            module M11
              module ::M111; end
              class M1::M2::M1; end
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
        module ::B; end
        module A::B::C; end
        module ::A::B; end
      RBI
      assert_rbi_same(rbi)
    end

    def test_parse_classes
      rbi = <<~RBI
        class A; end
        class ::B < A; end
        class A::B::C < A::B; end
        class ::A::B < ::A::B; end
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

    # Consts

    def test_parse_consts
      rbi = <<~RBI
        A = nil
        B = 42
        C = 3.14
        D = "foo"
        E = :s
        F = CONST
        G = T.nilable(Foo)
        H = Foo.new
        I = T::Array[String].new
        J = [1, "foo", {a: "String"}]
        ::Z = CONST
        C::C::C = C::C::C
        C::C = foo
        ::C::C = foo
      RBI
      assert_rbi_same(rbi)
    end

    # Defs

    def test_parse_methods
      rbi = <<~RBI
        def foo; end
        def foo(x, *y, z:); end
        def foo(p1, p2 = 42, *p3); end
        def foo(p1:, p2: "foo", **p3); end
        def self.foo(p1:, p2: 3.14, p3: nil, &block); end
        def self.foo(p1: T.let("", String), p2: T::Array[String].new, p3: [1, 2, {}]); end
      RBI
      assert_rbi_same(rbi)
    end

    # Sends

    def test_parse_sends
      rbi = <<~RBI
        include A
        extend B
        prepend C, D
        mixes_in_class_methods A, B, C
        sealed!
        interface!
        abstract!
        attr_reader :a
        attr_writer :a
        attr_accessor :a, :b
      RBI
      assert_rbi_same(rbi)
    end

    def test_parse_visibility
      rbi = <<~RBI
        public
        private
        protected
      RBI
      assert_rbi_same(rbi)
    end

    def test_parse_ignore_sends_not_on_self
      rbi = <<~RBI
        Foo.include A
        a.abtract!
        self.mixes_in_class_methods C, D
      RBI
      assert_rbi_equal("mixes_in_class_methods C, D\n", rbi)
    end

    def test_parse_sigs
      rbi = <<~RBI
        sig { void }
        sig { returns(String) }
        sig { params(a: T.untyped, b: T::Array[String]).returns(T::Hash[String, Integer]) }
        sig { abstract.params(a: Integer).void }
        sig { returns(T::Array[String]) }
        sig { override.params(printer: Spoom::LSP::SymbolPrinter).void }
        sig { returns(T.nilable(String)) }
        sig { params(requested_generators: T::Array[String]).returns(T.proc.params(klass: Class).returns(T::Boolean)) }
        sig { type_parameters(:U).params(step: Integer, _blk: T.proc.returns(T.type_parameter(:U))).returns(T.type_parameter(:U)) }
        def foo; end
      RBI
      assert_rbi_same(rbi)
    end
  end
end
