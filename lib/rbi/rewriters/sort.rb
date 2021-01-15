# typed: strict
# frozen_string_literal: true

class RBI
  extend T::Sig

  sig { returns(RBI) }
  def sort
    v = Rewriters::Sort.new
    v.sort(self)
    self
  end

  module Rewriters
    class Sort < Base
      extend T::Sig

      sig { void }
      def initialize
        super
      end

      sig { params(rbi: RBI).void }
      def sort(rbi)
        visit(rbi.root)
      end

      private

      sig { override.params(node: T.nilable(Node)).void }
      def visit(node)
        return unless node.is_a?(Scope)
        visit_all(node.body)
        node.body.sort! do |a, b|
          res = kind_rank(a) <=> kind_rank(b)
          res = node_name(a) <=> node_name(b) if res == 0
          res || 0
        end
      end

      sig { params(node: Node).returns(Integer) }
      def kind_rank(node)
        case node
        when Include, Prepend, Extend
          0
        when Scope, Const
          1
        when Attr
          2
        when Def
          3
        else
          4
        end
      end

      sig { params(node: Node).returns(T.nilable(String)) }
      def node_name(node)
        case node
        when Scope
          node.name
        when Const
          node.name
        when Def
          node.name
        when Send
          "#{node.method}(#{node.args.join(",")})"
        end
      end
    end
  end
end
