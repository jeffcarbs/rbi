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
    class SigTemplates < Rewriter
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

  class Def
    extend T::Sig

    sig { returns(Sig) }
    def template_sig
      sig = Sig.new
      unless params.empty?
        sig << Sig::Params.new(
          params.map do |param|
            type = case param
            when OptParam, KwOptParam
              if param.value =~ /\bnil\b/
                "T.nilable(T.untyped)"
              else
                "T.untyped"
              end
            when RestParam
              "T::Array[T.untyped]"
            when KwRestParam
              "T::Hash[T.untyped, T.untyped]"
            when BlockParam
              "T.proc.params(*args: T.untyped).returns(T.untyped)"
            else
              "T.untyped"
            end
            Sig::Param.new(param.name, type: type)
          end
        )
      end
      sig << Sig::Returns.new("T.untyped")
      sig
    end
  end

  class Attr
    extend T::Sig

    sig { abstract.returns(Sig) }
    def template_sig; end
  end

  class AttrReader
    extend T::Sig

    sig { override.returns(Sig) }
    def template_sig
      sig = Sig.new
      sig << Sig::Returns.new("T.untyped")
      sig
    end
  end

  class AttrWriter
    extend T::Sig

    sig { override.returns(Sig) }
    def template_sig
      sig = Sig.new
      sig << Sig::Params.new(names.map { |name| Sig::Param.new(name.to_s, type: "T.untyped") })
      sig << Sig::Void.new
      sig
    end
  end

  class AttrAccessor
    extend T::Sig

    sig { override.returns(Sig) }
    def template_sig
      sig = Sig.new
      sig << Sig::Params.new(names.map { |name| Sig::Param.new(name.to_s, type: "T.untyped") })
      sig << Sig::Returns.new("T.untyped")
      sig
    end
  end
end
