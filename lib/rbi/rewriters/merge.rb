# typed: strict
# frozen_string_literal: true

class RBI
  extend T::Sig

  sig { params(other: RBI).returns(RBI) }
  def merge(other)
    v = Rewriters::Merge.new
    v.merge(self)
    v.merge(other)
    v.rbi
  end

  module Rewriters
    class Merge < Base
      extend T::Sig

      sig { returns(RBI) }
      attr_reader :rbi

      sig { void }
      def initialize
        super
        @rbi = T.let(RBI.new, RBI)
      end

      sig { params(rbi: RBI).void }
      def merge(rbi)
        visit(rbi.root)
      end

      private

      sig { override.params(node: T.nilable(Node)).void }
      def visit(node)
      end
    end
  end
end
