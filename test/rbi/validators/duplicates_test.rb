# typed: true
# frozen_string_literal: true

require "test_helper"

class RBI
  module Validators
    class DuplicatesTest < Minitest::Test
      include TestHelper

      def test_validate_empty
        rbi = parse("")
        assert_empty(rbi.validate_duplicates)
      end

      def test_validate
        rbi = parse(<<~RBI)
          class A; end
          class A; end
        RBI
        assert_equal(["::A defined multiple times"], rbi.validate_duplicates)
      end
    end
  end
end
