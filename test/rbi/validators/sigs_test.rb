# typed: true
# frozen_string_literal: true

require "test_helper"

class RBI
  module Validators
    class SigsTest < Minitest::Test
      include TestHelper

      def test_validate_empty
        errors = validate_sigs("")
        assert_empty(errors)
      end

      def test_validate_sigs
        errors = validate_sigs(<<~RBI)
          sig {}
          attr_reader :a, :b

          class A
            sig {}
            attr_writer :foo

            sig {}
            def foo; end

            module B::C
              sig {}
              attr_accessor :bar

              sig {}
              def self.bar; end
            end
          end

          sig {}
          def foo; end
        RBI
        assert_empty(errors)
      end

      def test_validate_sigs_errors
        errors = validate_sigs(<<~RBI)
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
          "Accessor `<cbase>#a, b` defined without a sig",
          "Accessor `A#foo` defined without a sig",
          "Method `foo` defined without a sig",
          "Accessor `B::C#bar` defined without a sig",
          "Method `bar` defined without a sig",
          "Method `foo` defined without a sig",
        ], errors.map(&:message))
      end

      private

      def validate_sigs(rbi)
        validate(rbi, validators: [Validator::Sigs.new])
      end
    end
  end
end
