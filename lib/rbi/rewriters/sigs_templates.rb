# typed: strict
# frozen_string_literal: true

class RBI
  extend T::Sig

  sig { returns(RBI) }
  def sigs_templates
    Rewriters::SigTemplates.new.add_templates(self.collect_sigs)
    self
  end

  sig { params(rbis: RBI).void }
  def self.sigs_templates(*rbis)
    v = Rewriters::SigTemplates.new
    v.visit_all(rbis.map(&:collect_sigs).map(&:root))
  end

  module Rewriters
    class SigTemplates < Base
      extend T::Sig

      sig { void }
      def initialize
        super()
      end

      sig { params(rbi: RBI).void }
      def add_templates(rbi)
        visit(rbi.root)
      end

      private

      sig { override.params(node: T.nilable(Node)).void }
      def visit(node)
        case node
        when Def
          return unless node.sigs.empty?
          node.sigs << node.template_sig
        when Attr
          return unless node.sigs.empty?
          node.sigs << node.template_sig
        when Scope
          visit_all(node.body)
        end
      end
    end
  end
end
