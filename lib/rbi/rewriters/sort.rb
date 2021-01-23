# typed: strict
# frozen_string_literal: true

class RBI
  extend T::Sig

  sig { returns(RBI) }
  def sort
    Rewriters::Sort.new.visit_rbi(self)
    self
  end

  sig { params(rbis: RBI).void }
  def self.sort(*rbis)
    Rewriters::Sort.new.visit_rbis(rbis)
  end

  module Rewriters
    class Sort < Rewriter
      extend T::Sig

      sig { void }
      def initialize
        super
      end

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

      private

      sig { params(node: Node).returns(Integer) }
      def kind_rank(node)
        case node
        when RBI::Group
          group_rank(node)
        when Include, Prepend, Extend
          0
        when Module, Class, Const
          1
        when Attr
          2
        when Def
          3
        else
          4
        end
      end

      sig { params(group: RBI::Group).returns(Integer) }
      def group_rank(group)
        case group.kind
        when :includes
          0
        when :sorbet
          1
        when :consts
          2
        when :attrs
          3
        when :defss
          4
        when :defs
          5
        when :scopes
          6
        else
          7
        end
      end

      sig { params(node: Node).returns(T.nilable(String)) }
      def node_name(node)
        case node
        when NamedScope, Const, Def
          node.name
        when Send
          "#{node.method}(#{node.args.join(',')})"
        end
      end
    end
  end
end
