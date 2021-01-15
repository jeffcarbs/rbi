# typed: strict
# frozen_string_literal: true

class RBI
  extend T::Sig

  sig { returns(RBI) }
  def flatten
    v = Rewriter::Flatten.new
    v.flatten(self)
    v.rbi
  end

  module Rewriter
    class Flatten < Base
      extend T::Sig

      sig { returns(RBI) }
      attr_reader :rbi

      sig { void }
      def initialize
        super
        @rbi = T.let(RBI.new, RBI)
        @scopes_stack = T.let([rbi.root], T::Array[Scope])
        @root_scope = T.let(rbi.root, Module)
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
        when InScope
          # nothing
        else
          raise "Unhandled #{node}"
        end
      end

      sig { params(scope: Scope).void }
      def visit_scope(scope)
        if scope.root?
          visit_all(scope.body)
          @root_scope.body.concat(scope.body)
          return
        end
        @scopes_stack << scope
        visit_all(scope.body)
        @scopes_stack.pop
        @root_scope << scope
        T.must(@scopes_stack.last).body.delete(scope)
        scope.name = "#{current_namespace}::#{scope.name}" unless scope.name.start_with?("::")
      end

      sig { params(const: Const).void }
      def visit_const(const)
        @root_scope << const
        T.must(@scopes_stack.last).body.delete(const)
        const.name = "#{current_namespace}::#{const.name}" unless const.name.start_with?("::")
      end
      sig { returns(String) }
      def current_namespace
        T.must(@scopes_stack[1..-1]).map(&:name).prepend("").join("::")
      end
    end
  end
end
