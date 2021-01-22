# typed: strict
# frozen_string_literal: true

class RBI
  class Rewriter < Visitor
    extend T::Helpers

    abstract!
  end
end
