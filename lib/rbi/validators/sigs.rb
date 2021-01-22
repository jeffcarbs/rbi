# typed: strict
# frozen_string_literal: true

class RBI
  extend T::Sig

  module Validators
    class Sigs < Validator
      extend T::Sig

      sig { override.params(rbis: T::Array[RBI]).void }
      def validate(rbis)
        rbis.each do |rbi|
          visit(rbi.collect_sigs.root)
        end
      end

      sig { override.params(node: T.nilable(Node)).void }
      def visit(node)
        case node
        when Def
          return unless node.sigs.empty?
          @errors << Validator::Error.new("Method `#{node.name}` defined without a sig", loc: node.loc)
        when Attr
          return unless node.sigs.empty?
          @errors << Validator::Error.new("Accessor `#{node.named_parent_scope&.name}##{node.names.join(', ')}` defined without a sig",
                               loc: node.loc)
        when Scope
          visit_all(node.body)
        end
      end
    end
  end
end
