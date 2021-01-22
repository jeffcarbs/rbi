# typed: strict
# frozen_string_literal: true

class RBI
  extend T::Sig

  sig { params(rbis: RBI).returns(RBI) }
  def inflate(*rbis)
    rbis.prepend(self)
    v = Rewriters::Inflate.new
    v.inflate(rbis)
    v.rbi.merge
  end

  sig { params(rbis: RBI).returns(RBI) }
  def self.inflate(*rbis)
    v = Rewriters::Inflate.new
    v.inflate(rbis)
    v.rbi.merge
  end

  module Rewriters
    class Inflate < Rewriter
      extend T::Sig

      sig { returns(RBI) }
      attr_reader :rbi

      sig { void }
      def initialize
        super
        @rbi = T.let(RBI.new, RBI)
        @index = T.let(Index.new, Index)
      end

      sig { params(rbis: T::Array[RBI]).void }
      def inflate(rbis)
        roots = rbis.map(&:root)
        @index.visit_all(roots)
        visit_all(roots)
      end

      sig { override.params(node: T.nilable(Node)).void }
      def visit(node)
        return unless node

        case node
        when CBase
          visit_all(node.body)
        when NamedScope, Const
          inflate_namespace(node)
        end
      end

      private

      sig { params(node: T.any(NamedScope, Const)).void }
      def inflate_namespace(node)
        copy = node.dup
        names = node.qualified_name.split(/::/)
        scope = T.let(@rbi.root, NamedScope)
        names[1...-1]&.each do |parent|
          prev = @index["#{scope.index_id}::#{parent}"].first
          # TODO error if not prev, don't know how to inflate
          raise unless prev
          inner = T.cast(prev, NamedScope).stub_empty
          inner.name = parent
          scope << inner
          scope = inner
        end
        copy.name = T.must(names.last)
        scope << copy
      end
    end
  end
end
