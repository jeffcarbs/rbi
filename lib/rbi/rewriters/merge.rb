# typed: strict
# frozen_string_literal: true

class RBI
  extend T::Sig

  sig { params(rbis: RBI).returns(RBI) }
  def merge(*rbis)
    v = Rewriters::Merge.new
    v.merge(self)
    rbis.each { |rbi| v.merge(rbi) }
    v.rbi
  end

  class Scope
    extend T::Sig

    sig { params(other: Scope).void }
    def merge(other)
      concat(other.body)
    end
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
        @index = T.let(Index.new, Index)
        @scope_stack = T.let([@rbi.root], T::Array[Scope])
      end

      sig { params(rbi: RBI).void }
      def merge(rbi)
        visit(rbi.root)
      end

      private

      sig { override.params(node: T.nilable(Node)).void }
      def visit(node)
        return unless node

        prev = @index[@index.id_for(node)].first
        scope = T.must(@scope_stack.last)

        case node
        when CBase
          visit_all(node.body)
        when Scope
          if prev.is_a?(Scope)
            @scope_stack << prev
          else
            copy = node.dup_empty
            scope << copy
            @index << copy
            @scope_stack << copy
          end
          visit_all(node.body)
          @scope_stack.pop
        when Stmt
          return if prev
          copy = node.dup
          scope << copy
          @index << copy
        end
      end
    end
  end
end
