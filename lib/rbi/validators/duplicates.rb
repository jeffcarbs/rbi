# typed: strict
# frozen_string_literal: true

class RBI
  extend T::Sig

  sig { returns(T::Array[String]) }
  def validate_duplicates
    v = Validators::Duplicates.new(index)
    v.validate
  end

  module Validators
    class Duplicates
      extend T::Sig

      sig { params(index: Index).void }
      def initialize(index)
        super()
        @index = index
      end

      sig { returns(T::Array[String]) }
      def validate
        errors = []
        @index.each do |id, nodes|
          if nodes.size > 1
            errors << "#{id} defined multiple times"
          end
        end
        errors
      end
    end
  end
end
