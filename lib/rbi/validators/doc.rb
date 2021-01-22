# typed: strict
# frozen_string_literal: true

class RBI
  extend T::Sig

  module Validators
    class Doc < Validator
      extend T::Sig

      sig { override.params(rbis: T::Array[RBI]).void }
      def validate(rbis)
        rbis.each do |rbi|
          visit(rbi.root)
        end
      end

      sig { override.params(node: T.nilable(Node)).void }
      def visit(node)
        case node
        when Def
          return unless node.comments.empty?
          @errors << Validator::Error.new("Method `#{node.name}` declared without documentation", loc: node.loc)
        when Scope
          visit_all(node.body)
        end
      end
    end
  end
end
