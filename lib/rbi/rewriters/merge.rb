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
        @index = T.let(@rbi.index, Index)
      end

      sig { params(rbi: RBI).void }
      def merge(rbi)
        visit(rbi.root)
      end

      private

      sig { override.params(node: T.nilable(Node)).void }
      def visit(node)
        case node
        when Scope
          @index << node unless node.is_a?(CBase)
          visit_all(node.body)
        when Const, Def, Send
          @index << node
        end
      end
    end
  end
end
