# typed: true
# frozen_string_literal: true

require "test_helper"

class RBI
  module Validators
    class DuplicatesTest < Minitest::Test
      include TestHelper

      def test_validate_empty
        status, errors = validate("")
        assert(status)
        assert_empty(errors)
      end

      def test_validate
        status, errors = validate(<<~RBI)
          class A; end
          class A; end
        RBI
        refute(status)
        assert_equal(["Duplicated definitions for `::A`"], errors.map(&:message))
      end
    end
  end
end
