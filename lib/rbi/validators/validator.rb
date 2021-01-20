# typed: strict
# frozen_string_literal: true

class RBI
  class Validator < Visitor
    extend T::Helpers
    extend T::Sig

    abstract!

    sig { abstract.params(rbis: T::Array[RBI]).returns(T::Array[Error]) }
    def validate(rbis); end

    class Error < RBI::Error; end
  end
end
