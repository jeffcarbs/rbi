# typed: strict
# frozen_string_literal: true

class RBI
  extend T::Sig

  sig { returns(RBI) }
  def sigs_templates
    v = Rewriters::SigTemplates.new
    v.add_templates(self)
    self
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
          visit_all(node.body)
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
