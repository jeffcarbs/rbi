# typed: strict
# frozen_string_literal: true

class RBI
  class Validator
    extend T::Helpers
    extend T::Sig

    abstract!

    sig { returns(T::Array[Error]) }
    attr_reader :errors

    sig { void }
    def initialize
      @errors = T.let([], T::Array[Error])
    end

    sig { abstract.returns(T::Boolean) }
    def validate; end

    class Error < RBI::Error; end
  end
end
