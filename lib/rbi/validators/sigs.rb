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
          message = "Method `#{node.qualified_name}` defined without a sig"
          @errors << Validator::Error.new(message, loc: node.loc)
        when Attr
          return unless node.sigs.empty?
          name = "#{node.named_parent_scope&.qualified_name}##{node.names.join(',')}"
          message = "Accessor `#{name}` defined without a sig"
          @errors << Validator::Error.new(message, loc: node.loc)
        when Scope
          visit_all(node.body)
        end
      end
    end
  end
end
