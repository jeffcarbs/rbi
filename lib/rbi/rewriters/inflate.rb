# typed: strict
# frozen_string_literal: true

class RBI
  extend T::Sig

  sig { params(rbis: RBI).returns(RBI) }
  def inflate(*rbis)
    T.unsafe(RBI).inflate(self, *rbis)
  end

  sig { params(rbis: RBI).returns(RBI) }
  def self.inflate(*rbis)
    v = Rewriters::Inflate.new
    v.inflate(rbis)
    v.rbi.merge
  end

  module Rewriters
    class Inflate < Base
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

      private

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
            prev = @index[@index.id_for(node)].first
            # TODO error if not prev
            inner = case prev
                    when Module
                      Module.new(parent)
                    when Class
                      # TODO save ancestors?
                      Class.new(parent)
                    when SClass
                      SClass.new
                    else
                      raise
                    end
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
