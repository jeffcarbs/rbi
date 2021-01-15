# typed: strict
# frozen_string_literal: true

class RBI
  extend T::Sig

  sig { returns(RBI) }
  def flatten
    v = Rewriters::Flatten.new
    v.flatten(self)
    v.rbi
  end

  module Rewriters
    class Flatten < Base
      extend T::Sig

      sig { returns(RBI) }
      attr_reader :rbi

      sig { void }
      def initialize
        super
        @rbi = T.let(RBI.new, RBI)
        @scopes_stack = T.let([rbi.root], T::Array[Scope])
      end

      sig { params(rbi: RBI).void }
      def flatten(rbi)
        visit(rbi.root)
      end

      private

      sig { override.params(node: T.nilable(Node)).void }
      def visit(node)
        case node
        when Scope
          visit_scope(node)
        when Const
          visit_const(node)
        when Stmt
          # nothing
        else
          raise "Unhandled #{node}"
        end
      end

      sig { params(scope: Scope).void }
      def visit_scope(scope)
        if scope.root?
          visit_all(scope.body)
          @rbi.root.body.concat(scope.body)
          return
        end
        @scopes_stack << scope
        visit_all(scope.body)
        scope.name = current_namespace unless scope.name.start_with?("::")
        @scopes_stack.pop
        move_node(scope)
      end

      sig { params(const: Const).void }
      def visit_const(const)
        const.name = "#{current_namespace}::#{const.name}" unless const.name.start_with?("::")
        move_node(const)
      end

      sig { returns(String) }
      def current_namespace
        T.must(@scopes_stack[1..-1]).map(&:name).prepend("").join("::")
      end

      sig { params(node: Stmt).void }
      def move_node(node)
        @rbi << node
        T.must(@scopes_stack.last).body.delete(node)
      end
    end
  end
end
