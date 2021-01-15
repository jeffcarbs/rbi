# typed: strict
# frozen_string_literal: true

class RBI
  module Validators
    class Base < Visitor
      extend T::Helpers

      abstract!
    end
  end
end
