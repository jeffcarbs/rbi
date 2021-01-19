# typed: true
# frozen_string_literal: true

require "test_helper"

class RBI
  module Rewriters
    class CollectSigsTest < Minitest::Test
      include TestHelper

      def test_collect_sigs
        index = collect(<<~RBI)
          sig {}
          sig {}
          def foo; end

          sig {}

          class Foo
            def foo; end

            sig {}
            def bar; end

            sig {}
          end

          def bar; end

          sig {}
          attr_reader :foo
        RBI
        assert_equal(2, index["#foo"][0].sigs.size)
        assert_equal(0, index["#bar"][0].sigs.size)
        assert_equal(0, index["::Foo#foo"][0].sigs.size)
        assert_equal(1, index["::Foo#bar"][0].sigs.size)
      end

      private

      def collect(rbi)
        parse(rbi).collect_sigs.index
      end
    end
  end
end
