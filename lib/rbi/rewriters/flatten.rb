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
        @scope_stack = T.let([@rbi.root], T::Array[Scope])
      end

      sig { params(rbi: RBI).void }
      def flatten(rbi)
        visit(rbi.root)
      end

      private

      sig { override.params(node: T.nilable(Node)).void }
      def visit(node)
        return unless node
        scope = T.must(@scope_stack.last)

        case node
        when CBase
          visit_all(node.body)
        when Module, Class, SClass
          copy = node.dup_empty
          copy.name = node.qualified_name
          @scope_stack << copy
          visit_all(node.body)
          @scope_stack.pop
          @rbi.root << copy
        when Const
          copy = node.dup
          copy.name = node.qualified_name
          @rbi.root << copy
        when Stmt
          scope << node.dup
        end
      end
    end
  end
end
