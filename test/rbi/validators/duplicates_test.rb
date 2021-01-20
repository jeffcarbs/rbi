# typed: true
# frozen_string_literal: true

require "test_helper"

class RBI
  module Validators
    class DuplicatesTest < Minitest::Test
      include TestHelper

      def test_validate_empty
        errors = validate_dups("")
        assert_empty(errors)
      end

      def test_validate_accept_scopes_redefinitions_if_only_namespacing
        errors = validate_dups(<<~RBI)
          class A
            def foo; end

            module B::C
              def bar; end
            end
          end

          class A
            module B
              module C
                module D
                  def bar; end
                end
              end
            end
          end
        RBI
        assert_empty(errors)
      end

      def test_validate_reject_scopes_redefinitions_if_reopening
        errors = validate_dups(<<~RBI)
          class A
            def foo; end

            module B
              include X
              module C
                attr_accessor :bar
                class << self
                  DD = D
                end
              end
            end
          end

          class A
            include X
            module B
              BB = B
              module C
                def foo; end
                class << self
                  attr_reader :bar
                end
              end
            end
          end
        RBI
        assert_equal([
          "Duplicated definitions for `::A`. Defined here:",
          "Duplicated definitions for `::A::B`. Defined here:",
          "Duplicated definitions for `::A::B::C`. Defined here:",
          "Duplicated definitions for `::A::B::C::<self>`. Defined here:",
        ], errors.map(&:message))
      end

      def test_validate_reject_scopes_redefinitions_if_empty
        errors = validate_dups(<<~RBI)
          class A
            def foo; end

            module B::C
              def bar; end
            end
          end

          class A; end

          class A
            module B
              module C
                module D
                end
              end
            end
          end

          module A::B::C; end
        RBI
        assert_equal([
          "Duplicated definitions for `::A`. Defined here:",
          "Duplicated definitions for `::A::B`. Defined here:",
          "Duplicated definitions for `::A::B::C`. Defined here:",
          "Duplicated definitions for `::A::B::C::<self>`. Defined here:",
        ], errors.map(&:message))
      end

      private

      def validate_dups(rbi)
        validate(rbi, validators: [Validator::Duplicates.new])
      end
    end
  end
end
