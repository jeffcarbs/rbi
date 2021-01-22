# typed: strict
# frozen_string_literal: true

class RBI
  extend T::Sig

  sig { returns(RBI) }
  def sigs_templates
    Rewriters::SigTemplates.new.visit_rbi(self.collect_sigs)
    self
  end

  sig { params(rbis: RBI).void }
  def self.sigs_templates(*rbis)
    Rewriters::SigTemplates.new.visit_rbis(rbis.map(&:collect_sigs))
  end

  module Rewriters
    class SigTemplates < Base
      extend T::Sig

      sig { void }
      def initialize
        super()
      end

      sig { override.params(node: T.nilable(Node)).void }
      def visit(node)
        case node
        when Def, Attr
          return unless node.sigs.empty?
          node.sigs << node.template_sig
        when Scope
          visit_all(node.body)
        end
      end
    end
  end
end
