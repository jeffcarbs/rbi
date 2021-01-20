# typed: strict
# frozen_string_literal: true

class RBI
  extend T::Sig

  sig { returns(RBI) }
  def collect_sigs
    rbi = dup
    v = Rewriters::CollectSigs.new
    v.collect(rbi)
    rbi
  end

  module Rewriters
    class CollectSigs < Base
      extend T::Sig

      sig { void }
      def initialize
        super
        @sigs = T.let([], T::Array[Sig])
      end

      sig { params(rbi: RBI).void }
      def collect(rbi)
        visit(rbi.root)
      end

      private

      sig { override.params(node: T.nilable(Node)).void }
      def visit(node)
        case node
        when Module, Class
          @sigs.clear
          visit_all(node.body.dup)
          @sigs.clear
        when Def
          node.sigs.concat(@sigs)
          @sigs.clear
        when Attr
          node.sigs.concat(@sigs)
          @sigs.clear
        when Sig
          @sigs << node
          T.must(node.parent_scope).body.delete(node)
        end
      end
    end
  end
end
