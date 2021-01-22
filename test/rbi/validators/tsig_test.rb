# typed: true
# frozen_string_literal: true

require "test_helper"

class RBI
  module Validators
    class TSigTest < Minitest::Test
      include TestHelper

      def test_validate_empty
        errors = validate_doc("")
        assert_empty(errors)
      end

      def test_validate_doc
        errors = validate_doc(<<~RBI)
          class A
            module B::C
            end
          end
        RBI
        assert_empty(errors)
      end

      def test_validate_doc_errors
        errors = validate_doc(<<~RBI)
          class A
            extend T::Sig
            module B::C
              extend T::Sig
            end
          end
        RBI
        assert_equal([
          "`T::Sig` used in RBI:",
          "`T::Sig` used in RBI:",
        ], errors.map(&:message))
      end

      private

      def validate_doc(rbi)
        validate(rbi, validators: [Validators::TSig.new])
      end
    end
  end
end
