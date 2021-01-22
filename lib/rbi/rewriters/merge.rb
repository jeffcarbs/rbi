# typed: strict
# frozen_string_literal: true

class RBI
  extend T::Sig

  sig { params(rbis: RBI).returns(RBI) }
  def merge(*rbis)
    v = Rewriters::Merge.new
    v.visit_rbi(self)
    v.visit_rbis(rbis)
    v.rbi
  end

  sig { params(rbis: RBI).returns(RBI) }
  def self.merge(*rbis)
    v = Rewriters::Merge.new
    v.visit_rbis(rbis)
    v.rbi
  end

  module Rewriters
    class Merge < Rewriter
      extend T::Sig

      sig { returns(RBI) }
      attr_reader :rbi

      sig { void }
      def initialize
        super
        @rbi = T.let(RBI.new, RBI)
        @index = T.let(Index.new, Index)
        @scope_stack = T.let([@rbi.root], T::Array[Scope])
      end

      sig { override.params(node: T.nilable(Node)).void }
      def visit(node)
        return unless node

        scope = T.must(@scope_stack.last)

        case node
        when CBase
          visit_all(node.body)
        when NamedScope
          prev = @index[node.index_id].first
          if prev.is_a?(Scope)
            @scope_stack << prev
          else
            copy = node.dup_empty
            scope << copy
            @index.visit(copy)
            @scope_stack << copy
          end
          visit_all(node.body)
          @scope_stack.pop
        when Def, Attr, Send, Const
          return if @index[node.index_id].first
          copy = node.dup
          scope << copy
          @index.visit(copy)
        end
      end
    end
  end
end
