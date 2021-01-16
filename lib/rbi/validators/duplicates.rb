# typed: strict
# frozen_string_literal: true

class RBI
  extend T::Sig

  module Validators
    class Duplicates
      extend T::Sig

      sig { params(index: Index).returns(T::Array[String]) }
      def validate(index)
        errors = []
        index.each do |id, nodes|
          if nodes.size > 1
            errors << "#{id} defined multiple times"
          end
        end
        errors
      end
    end
  end
end
