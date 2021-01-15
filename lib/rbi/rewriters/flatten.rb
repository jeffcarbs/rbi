# typed: strict
# frozen_string_literal: true

class RBI
  extend T::Sig

  sig { returns(RBI) }
  def flatten
    v = Rewriters::Flatten.new
    v.flatten(self)
    v.rbi
  end

  module Rewriters
    class Flatten < Base
      extend T::Sig

      sig { returns(RBI) }
      attr_reader :rbi

      sig { void }
      def initialize
        super
        @rbi = T.let(RBI.new, RBI)
      end

      sig { params(rbi: RBI).void }
      def flatten(rbi)
        visit(rbi.root)
      end

      private

      sig { override.params(node: T.nilable(Node)).void }
      def visit(node)
        case node
        when CBase
          visit_all(node.body.dup)
          @rbi.root.concat(node.body)
        when Scope
          visit_all(node.body.dup)
          node.name = node.qualified_name
          @rbi.root << node
        when Const
          node.name = node.qualified_name
          @rbi.root << node
        end
      end
    end
  end
end
