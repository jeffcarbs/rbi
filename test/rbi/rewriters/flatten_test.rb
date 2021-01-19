# typed: true
# frozen_string_literal: true

require "test_helper"

class RBI
  class FlattenTest < Minitest::Test
    include TestHelper

    def test_flatten_empty
      assert_flatten_equal("", "")
    end

    def test_flatten_scopes_empty
      rbi = <<~RBI
        class Foo; end
        module Bar; end
      RBI
      assert_flatten_equal(<<~EXP, rbi)
        class ::Foo; end
        module ::Bar; end
      EXP
    end

    def test_flatten_scopes_nested
      rbi = <<~RBI
        class Foo
          module Bar
            class Baz; end
          end
        end

        module Bar
          class Baz; end
        end
      RBI
      assert_flatten_equal(<<~EXP, rbi)
        class ::Foo::Bar::Baz; end
        module ::Foo::Bar; end
        class ::Foo; end
        class ::Bar::Baz; end
        module ::Bar; end
      EXP
    end

    def test_flatten_scopes_keep_body
      rbi = <<~RBI
        class Foo
          module Bar
            def foo; end
          end

          attr_reader :bar
        end

        module Bar
          extend T::Sig
        end

        def foo; end
      RBI
      assert_flatten_equal(<<~EXP, rbi)
        module ::Foo::Bar
          def foo; end
        end

        class ::Foo
          attr_reader :bar
        end

        module ::Bar
          extend T::Sig
        end

        def foo; end
      EXP
    end

    def test_flatten_scopes_keep_cbase
      rbi = <<~RBI
        class Foo
          module Bar
            class ::Baz; end
          end
        end

        module ::Bar
          class ::Baz; end
        end
      RBI
      assert_flatten_equal(<<~EXP, rbi)
        class ::Baz; end
        module ::Foo::Bar; end
        class ::Foo; end
        class ::Baz; end
        module ::Bar; end
      EXP
    end

    def test_flatten_scopes_move_constants
      rbi = <<~RBI
        class Foo
          module Bar
            BAR = 10
          end

          FOO = Foo::Bar
        end

        module Bar
          BAR = "Bar"
        end
      RBI
      assert_flatten_equal(<<~EXP, rbi)
        ::Foo::Bar::BAR = 10
        module ::Foo::Bar; end
        ::Foo::FOO = Foo::Bar
        class ::Foo; end
        ::Bar::BAR = \"Bar\"
        module ::Bar; end
      EXP
    end

    private

    def assert_flatten_equal(exp, rbi)
      res = parse(rbi).flatten
      assert_equal(exp, res.to_rbi)
    end
  end
end
