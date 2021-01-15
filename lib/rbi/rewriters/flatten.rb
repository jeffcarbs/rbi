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
          visit_cbase(node)
        when Scope
          visit_scope(node)
        when Const
          visit_const(node)
        end
      end

      sig { params(scope: CBase).void }
      def visit_cbase(scope)
        visit_all(scope.body.dup)
        @rbi.root.body.concat(scope.body)
      end

      sig { params(scope: Scope).void }
      def visit_scope(scope)
        visit_all(scope.body.dup)
        scope.name = scope.qualified_name
        @rbi.root << scope
      end

      sig { params(const: Const).void }
      def visit_const(const)
        const.name = const.qualified_name
        @rbi.root << const
      end
    end
  end
end
