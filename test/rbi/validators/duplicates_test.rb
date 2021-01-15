# typed: true
# frozen_string_literal: true

require "test_helper"

class RBI
  module Validators
    class DuplicatesTest < Minitest::Test
      extend T::Sig

      def test_validate_empty
        rbi = parse_rbi("")
        assert_empty(rbi.validate_duplicates)
      end

      def test_validate
        rbi = parse_rbi(<<~RBI)
          class A; end
          class A; end
        RBI
        assert_equal(["::A defined multiple times"], rbi.validate_duplicates)
      end

      private

      sig { params(rbi: String).returns(RBI) }
      def parse_rbi(rbi)
        T.must(RBI.from_string(rbi))
      end
    end
  end
end
