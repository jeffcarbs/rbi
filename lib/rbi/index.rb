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

    sig { params(id: String).returns(T::Array[Node]) }
    def [](id)
      @index[id] ||= []
    end

    sig { params(node: Node).void }
    def <<(node)
      self[id_for(node)] << node
    end

    sig { params(block: T.proc.params(pair: [String, T::Array[Node]]).void).void }
    def each(&block)
      @index.each(&block)
    end

    sig { returns(T::Boolean) }
    def empty?
      @index.empty?
    end

    sig { params(node: Node).returns(String) }
    def id_for(node)
      case node
      when Scope
        node.qualified_name
      when Const
        node.qualified_name
      when Def
        node.qualified_name
      when Send
        node.qualified_name
      else
        raise "Can't create id for #{node}"
      end
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
      end

      sig { params(rbi: RBI).void }
      def <<(rbi)
        visit(rbi.root)
      end

      protected

      sig { override.params(node: T.nilable(Node)).void }
      def visit(node)
        case node
        when Scope
          @index << node unless node.is_a?(CBase)
          visit_all(node.body)
        when Const, Def, Send
          @index << node
        end
      end
    end
  end
end