# typed: strict
# frozen_string_literal: true

class RBI
  class Validator < Visitor
    extend T::Helpers
    extend T::Sig

    abstract!

    sig { returns(T::Array[Error]) }
    attr_reader :errors

    sig { void }
    def initialize
      @errors = T.let([], T::Array[Error])
    end

    sig { abstract.params(rbis: T::Array[RBI]).void }
    def validate(rbis); end

    class Error < RBI::Error; end
  end
end
