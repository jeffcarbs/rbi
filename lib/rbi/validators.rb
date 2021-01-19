# typed: strict
# frozen_string_literal: true

class RBI
  extend T::Sig

  sig { returns([T::Boolean, T::Array[Validator::Error]]) }
  def validate
    RBI.validate([self])
  end

  sig { params(rbis: T::Array[RBI]).returns([T::Boolean, T::Array[Validator::Error]]) }
  def self.validate(rbis)
    index = RBI.index(rbis)
    validators = [Validator::Duplicates.new(index)]
    status = T.let(true, T::Boolean)
    errors = T.let([], T::Array[Validator::Error])
    validators.each do |v|
      status = false unless v.validate
      errors.concat(v.errors)
    end
    [status, errors]
  end
end
