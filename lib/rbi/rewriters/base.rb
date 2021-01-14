# typed: strict
# frozen_string_literal: true

class RBI
  module Rewriter
    class Base
      extend T::Helpers
      extend T::Sig

      abstract!

      protected

      sig { abstract.params(node: T.nilable(Node)).void }
      def visit(node); end

      sig { params(nodes: T::Array[Node]).void }
      def visit_all(nodes)
        nodes.each { |node| visit(node) }
      end
    end
  end
end
