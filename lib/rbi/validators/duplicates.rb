# typed: true
# frozen_string_literal: true

class RBI
  def check_duplicates
    v = Validators::Duplicates.new
    v << self
    v.check
  end

  module Validators
    class Duplicates < Base
      extend T::Sig

      sig { void }
      def initialize
        super
        @index = Index.new
        @scopes_stack = T.let([], T::Array[Scope])
      end

      sig { params(rbi: RBI).void }
      def <<(rbi)
        visit(rbi.root)
      end

      def check
      end

      private

      sig { override.params(node: T.nilable(Node)).void }
      def visit(node)
        case node
        when Scope
          visit_scope(node)
        when Const
          visit_const(node)
        when Def
          visit_def(node)
        when Send
          visit_send(node)
        end
      end

      sig { params(scope: Scope).void }
      def visit_scope(scope)
        @scopes_stack << scope
        @index[current_namespace] << scope
        visit_all(scope.body)
        @scopes_stack.pop
        scope.name = current_namespace unless scope.name.start_with?("::")
      end

      sig { params(const: Const).void }
      def visit_const(const)
        @index["#{current_namespace}.#{const}"] << const
      end

      def visit_def(node)
        if node.is_singleton
          @index["#{current_namespace}::#{node.name}"] << node
        else
          @index["#{current_namespace}##{node.name}"] << node
        end
      end

      def visit_send(node)
        @index["#{current_namespace}.#{node.method}(#{node.args.join(', ')})"] << node
      end

      sig { returns(String) }
      def current_namespace
        T.must(@scopes_stack[1..-1]).map(&:name).prepend("").join("::")
      end
    end

    class Index
      attr_reader :index

      def initialize
        @index = {}
      end

      def [](namespace)
        @index[namespace] ||= []
      end

      def to_s
        index.to_s
      end

      def pretty_print
        @index.each do |key, values|
          puts "#{key}: #{values.join(', ')}"
        end
      end
    end
  end
end
