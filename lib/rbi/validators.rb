# typed: strict
# frozen_string_literal: true

class RBI
  extend T::Sig

  sig { returns(T::Array[Validator::Error]) }
  def validate
    RBI.validate([self])
  end

  sig { params(rbis: T::Array[RBI], validators: T::Array[Validator]).returns(T::Array[Validator::Error]) }
  def self.validate(rbis, validators: default_validators)
    errors = T.let([], T::Array[Validator::Error])
    validators.each do |v|
      v.validate(rbis)
      errors.concat(v.errors)
    end
    errors
  end

  sig { returns(T::Array[Validator]) }
  def self.default_validators
    [
      Validators::Doc.new,
      Validators::Duplicates.new,
      Validators::Sigs.new,
      Validators::TSig.new,
    ]
  end
end
