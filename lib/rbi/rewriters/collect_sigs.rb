# typed: strict
# frozen_string_literal: true

class RBI
  extend T::Sig

  sig { returns(RBI) }
  def collect_sigs
    Rewriters::CollectSigs.new.visit_rbi(self)
    self
  end

  sig { params(rbis: RBI).void }
  def self.collect_sigs(*rbis)
    Rewriters::CollectSigs.new.visit_rbis(rbis)
  end

  module Rewriters
    class CollectSigs < Rewriter
      extend T::Sig

      sig { void }
      def initialize
        super
        @sigs = T.let([], T::Array[Sig])
      end

      sig { override.params(node: T.nilable(Node)).void }
      def visit(node)
        case node
        when NamedScope
          @sigs.clear
          visit_all(node.body.dup)
          @sigs.clear
        when Def, Attr
          node.sigs.concat(@sigs)
          @sigs.clear
        when Sig
          node.detach
          @sigs << node
        end
      end
    end
  end
end
