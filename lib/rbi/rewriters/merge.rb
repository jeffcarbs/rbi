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
          first = @index[@index.id_for(node)].first
          body = node.body.dup
          if first.is_a?(Scope)
            first.concat(node.body)
          else
            @index << node
            @rbi.root << node if node.parent_scope.is_a?(CBase)
          end
          visit_all(body.dup)
        end
      end
    end
  end
end
