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
        when NamedScope
          copy = node.dup
          names = node.qualified_name.split(/::/)
          scope = T.let(@rbi.root, Scope)
          names[1...-1]&.each do |parent|
            prev = @index[node.index_id].first
            # TODO error if not prev
            inner = T.cast(prev, Scope).stub_empty
            inner.name = parent
            scope << inner
            scope = inner
          end
          copy.name = T.must(names.last)
          scope << copy
        when Const
          # TODO factorize
          copy = node.dup
          names = node.qualified_name.split(/::/)
          scope = T.let(@rbi.root, Scope)
          names[1...-1]&.each do |parent|
            inner = Module.new(parent)
            scope << inner
            scope = inner
          end
          copy.name = T.must(names.last)
          scope << copy
        end
      end
    end
  end
end
