# typed: strict
# frozen_string_literal: true

class RBI
  extend T::Sig

  module Validators
    class TSig < Validator
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
        when Scope
          node.body.each do |child|
            next unless child.is_a?(Extend) && child.args.first == "T::Sig"
            @errors << Validator::Error.new("`T::Sig` used in RBI:", loc: child.loc)
          end
          visit_all(node.body)
        end
      end
    end
  end
end
