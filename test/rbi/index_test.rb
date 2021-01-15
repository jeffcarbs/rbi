# typed: true
# frozen_string_literal: true

require "test_helper"

class RBI
  class IndexTest < Minitest::Test
    extend T::Sig

    def test_index_empty
      index = parse_index("")
      assert(index.empty?)
    end

    def test_index_nodes
      index = parse_index(<<~RBI)
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

      index.pretty_print
      assert_equal(["A", "::A"], index["::A"].map(&:name))
      assert_equal(["B"], index["::A::B"].map(&:name))
      assert_equal(["B"], index["::B"].map(&:name))
      assert_equal(["foo"], index["::A::B#foo"].map(&:name))
      assert_equal([[:foo]], index["::A::B.attr_reader(foo)"].map(&:names))
    end

    private

    sig { params(rbi: String).returns(T.untyped) }
    def parse_index(rbi)
      T.must(RBI.from_string(rbi)).index
    end
  end
end
