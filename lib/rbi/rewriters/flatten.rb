# typed: strict
# frozen_string_literal: true

class RBI
  extend T::Sig

  sig { returns(RBI) }
  def flatten
    v = Rewriters::Flatten.new
    v.visit_rbi(self)
    v.rbi
  end

  sig { params(rbis: RBI).returns(RBI) }
  def self.flatten(*rbis)
    v = Rewriters::Flatten.new
    v.visit_rbis(rbis)
    v.rbi
  end

  module Rewriters
    class Flatten < Rewriter
      extend T::Sig

      sig { returns(RBI) }
      attr_reader :rbi

      sig { void }
      def initialize
        super
        @rbi = T.let(RBI.new, RBI)
        @scope_stack = T.let([@rbi.root], T::Array[Scope])
      end

      sig { override.params(node: T.nilable(Node)).void }
      def visit(node)
        return unless node
        scope = T.must(@scope_stack.last)

        case node
        when CBase
          visit_all(node.body)
        when Module, Class
          copy = node.dup_empty
          copy.name = node.qualified_name
          @rbi.root << copy
          @scope_stack << copy
          visit_all(node.body)
          @scope_stack.pop
        when SClass
          copy = node.dup_empty
          scope << copy
          @scope_stack << copy
          visit_all(node.body)
          @scope_stack.pop
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
