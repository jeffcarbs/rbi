# typed: true
# frozen_string_literal: true

require "test_helper"

class RBI
  module Validators
    class DocTest < Minitest::Test
      include TestHelper

      def test_validate_empty
        errors = validate_doc("")
        assert_empty(errors)
      end

      def test_validate_doc
        errors = validate_doc(<<~RBI)
          # Comment
          attr_reader :a, :b

          class A
            # Comment
            attr_writer :foo

            # Comment
            def foo; end

            module B::C
              # Comment
              attr_accessor :bar

              # Comment
              def self.bar; end
            end
          end

          # Comment
          def foo; end
        RBI
        assert_empty(errors)
      end

      def test_validate_doc_errors
        errors = validate_doc(<<~RBI)
          attr_reader :a, :b

          class A
            attr_writer :foo

            def foo; end

            module B::C
              attr_accessor :bar

              def self.bar; end
            end
          end

          def foo; end
        RBI
        assert_equal([
          "Method `foo` declared without documentation",
          "Method `bar` declared without documentation",
          "Method `foo` declared without documentation",
        ], errors.map(&:message))
      end

      private

      def validate_doc(rbi)
        validate(rbi, validators: [Validators::Doc.new])
      end
    end
  end
end
