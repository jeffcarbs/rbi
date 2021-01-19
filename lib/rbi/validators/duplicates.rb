# typed: strict
# frozen_string_literal: true

class RBI
  extend T::Sig

  class Validator
    class Duplicates < Validator
      extend T::Sig

      sig { params(index: Index).void }
      def initialize(index)
        super()
        @index = index
      end

      sig { override.returns(T::Boolean) }
      def validate
        @index.each do |id, nodes|
          next unless nodes.size > 1
          error = Error.new("Duplicated definitions for `#{id}`", loc: nodes.first&.loc)
          nodes.each do |node|
            error << RBI::Error::Section.new("defined here:", loc: node.loc)
          end
          @errors << error
        end
        errors.empty?
      end
    end
  end
end
