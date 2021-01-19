# typed: true
# frozen_string_literal: true

require "test_helper"

class RBI
  module Rewriters
    class SortTest < Minitest::Test
      include TestHelper

      def test_sort
        rbi = sort(<<~RBI)
          def b; end

          class B; end
          class A; end

          class C
            class E
              def a; end
              attr_accessor :b
              C = 10
            end

            class D; end
          end

          def a; end
        RBI
        assert_equal(<<~EXP, rbi.to_rbi)
          class A; end
          class B; end

          class C
            class D; end

            class E
              C = 10
              attr_accessor :b
              def a; end
            end
          end

          def a; end
          def b; end
        EXP
      end

      private

      def sort(rbi)
        parse(rbi).sort
      end
    end
  end
end
