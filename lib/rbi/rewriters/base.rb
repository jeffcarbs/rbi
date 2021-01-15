# typed: strict
# frozen_string_literal: true

class RBI
  module Rewriter
    class Base < Visitor
      extend T::Helpers
      extend T::Sig

      abstract!
    end
  end
end
