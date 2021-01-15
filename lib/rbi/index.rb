# typed: strict
# frozen_string_literal: true

class RBI
  extend T::Sig

  sig { returns(Index) }
  def index
    v = Index::Indexer.new
    v << self
    v.index
  end

  class Index
    extend T::Sig
    include T::Enumerable

    sig { void }
    def initialize
      @index = T.let({}, T::Hash[String, T::Array[Node]])
    end

    sig { params(namespace: String).returns(T::Array[Node]) }
    def [](namespace)
      @index[namespace] ||= []
    end

    def <<(node)
    end

    sig { params(block: T.proc.params(pair: [String, T::Array[Node]]).void).void }
    def each(&block)
      @index.each(&block)
    end

    sig { returns(T::Boolean) }
    def empty?
      @index.empty?
    end

    sig { returns(String) }
    def to_s
      @index.to_s
    end

    sig { void }
    def pretty_print
      @index.each do |key, values|
        puts "#{key}: #{values.join(', ')}"
      end
    end

    class Indexer < Visitor
      extend T::Sig

      sig { returns(Index) }
      attr_reader :index

      sig { void }
      def initialize
        super
        @index = T.let(Index.new, Index)
        @scopes_stack = T.let([], T::Array[Scope])
      end

      sig { params(rbi: RBI).void }
      def <<(rbi)
        visit(rbi.root)
      end

      protected

      sig { override.params(node: T.nilable(Node)).void }
      def visit(node)
        id = case node
        when Scope
          @scopes_stack << node
          visit_all(node.body)
          @scopes_stack.pop
          if node.name.start_with?("::")
            node.name
          elsif !node.root?
            "#{current_namespace}::#{node.name}"
          end
        when Const
          "#{current_namespace}.#{node.name}"
        when Def
          "#{current_namespace}#{node.is_singleton ? '::' : '#' }#{node.name}"
        when Send
          "#{current_namespace}.#{node.method}(#{node.args.join(', ')})"
        end
        @index[id] << node if id
      end

      sig { returns(String) }
      def current_namespace
        T.must(@scopes_stack[1..-1]).map(&:name).prepend("").join("::")
      end
    end
  end
end
