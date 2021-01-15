# typed: strict
# frozen_string_literal: true

class RBI
  module Rewriters
    class Base < Visitor
      extend T::Helpers

      abstract!
    end
  end
end
