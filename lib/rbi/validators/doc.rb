# typed: strict
# frozen_string_literal: true

class RBI
  extend T::Sig

  class Validator
    class Doc < Validator
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
        when Def
          return unless node.comments.empty?
          @errors << Error.new("Method `#{node.name}` declared without documentation", loc: node.loc)
        when Scope
          visit_all(node.body)
        end
      end
    end
  end
end
