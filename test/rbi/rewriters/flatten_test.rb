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
        class ::Foo; end
        module ::Foo::Bar; end
        class ::Foo::Bar::Baz; end
        module ::Bar; end
        class ::Bar::Baz; end
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
        class ::Foo
          attr_reader :bar
        end

        module ::Foo::Bar
          def foo; end
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
        class ::Foo; end
        module ::Foo::Bar; end
        class ::Baz; end
        module ::Bar; end
        class ::Baz; end
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
        class ::Foo; end
        module ::Foo::Bar; end
        ::Foo::Bar::BAR = 10
        ::Foo::FOO = Foo::Bar
        module ::Bar; end
        ::Bar::BAR = \"Bar\"
      EXP
    end

    def test_flatten_scopes_dont_move_singletons
      rbi = <<~RBI
        class Foo
          class << self
            def foo; end
          end

          module Bar
            class << self
              BAR = 10
            end
          end
        end
      RBI
      assert_flatten_equal(<<~EXP, rbi)
        class ::Foo
          class << self
            def foo; end
          end
        end

        module ::Foo::Bar
          class << self; end
        end

        ::Foo::Bar::BAR = 10
      EXP
    end

    private

    def assert_flatten_equal(exp, rbi)
      assert_equal(exp, parse(rbi).flatten.to_rbi)
    end
  end
end
