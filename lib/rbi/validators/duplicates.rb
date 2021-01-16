# typed: strict
# frozen_string_literal: true

class RBI
  extend T::Sig

  module Validators
    class Error < RBI::Error; end

    class Duplicates
      extend T::Sig

      sig { params(index: Index).returns(T::Array[String]) }
      def validate(index)
        errors = []
        index.each do |id, nodes|
          if nodes.size > 1
            error = Error.new("Duplicated definitions for `#{id}`", loc: nodes.first&.loc)
            nodes.each do |node|
              error << RBI::Error::Section.new("defined here:", loc: node.loc)
            end
            errors << error
          end
        end
        errors
      end
    end
  end
end
