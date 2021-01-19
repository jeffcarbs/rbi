# typed: true
# frozen_string_literal: true

require "test_helper"

class RBI
  class IndexTest < Minitest::Test
    include TestHelper

    def test_index_empty
      index = self.index("")
      assert(index.empty?)
    end

    def test_index_nodes
      index = self.index(<<~RBI)
        class A
          extend T::Helpers
          extend T::Sig

          abstract!

          module B
            attr_reader :foo

            module ::C; end

            def foo(a); end
          end
        end

        module B
          class ::A; end
        end
      RBI

      assert_equal(["A", "::A"], index["::A"].map(&:name))
      assert_equal(["B"], index["::A::B"].map(&:name))
      assert_equal(["B"], index["::B"].map(&:name))
      assert_equal(["foo"], index["::A::B#foo"].map(&:name))
      assert_equal([["foo"]], index["::A::B.attr_reader(foo)"].map(&:names))
    end

    private

    def index(rbi)
      parse(rbi).index
    end
  end
end
