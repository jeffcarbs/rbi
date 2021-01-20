# typed: strict
# frozen_string_literal: true

class RBI
  extend T::Sig

  class Validator
    class TSig < Validator
      extend T::Sig

      sig { void }
      def initialize
        super()
        @errors = T.let([], T::Array[Error])
      end

      sig { override.params(rbis: T::Array[RBI]).returns(T::Array[Error]) }
      def validate(rbis)
        @errors.clear
        rbis.each do |rbi|
          visit(rbi.root)
        end
        @errors
      end

      sig { override.params(node: T.nilable(Node)).void }
      def visit(node)
        case node
        when Scope
          node.body.each do |child|
            next unless child.is_a?(Extend) && child.args.first == "T::Sig"
            @errors << Error.new("`T::Sig` used in RBI:", loc: child.loc)
          end
          visit_all(node.body)
        end
      end
    end
  end
end
