# typed: strict
# frozen_string_literal: true

class RBI
  extend T::Sig

  sig { returns(Index) }
  def index
    RBI.index([self])
  end

  sig { params(rbis: T::Array[RBI]).returns(Index) }
  def self.index(rbis)
    index = Index.new
    index.visit_rbis(rbis)
    index
  end

  class Index < Visitor
    extend T::Sig
    include T::Enumerable

    sig { void }
    def initialize
      super()
      @index = T.let({}, T::Hash[String, T::Array[T.all(Node, Indexable)]])
    end

    sig { params(id: String).returns(T::Array[T.all(Node, Indexable)]) }
    def [](id)
      @index[id] ||= []
    end

    sig { returns(T::Boolean) }
    def empty?
      @index.empty?
    end

    sig { returns(T::Array[String]) }
    def keys
      @index.keys
    end

    sig { params(block: T.proc.params(pair: [String, T::Array[T.all(Node, Indexable)]]).void).void }
    def each(&block)
      @index.each(&block)
    end

    sig { params(out: T.any(IO, StringIO)).void }
    def pretty_print(out: $stdout)
      @index.each do |key, values|
        out.puts "#{key}: #{values.join(', ')}"
      end
    end

    sig { override.params(node: T.nilable(Node)).void }
    def visit(node)
      case node
      when CBase
        visit_all(node.body)
      when NamedScope
        index(node)
        visit_all(node.body)
      when Attr, Def, Const, Send
        index(node)
      end
    end

    private

    sig { params(node: T.all(Node, Indexable)).void }
    def index(node)
      self[node.index_id] << node
    end
  end

  module Indexable
    extend T::Helpers
    extend T::Sig

    interface!

    sig { abstract.returns(String) }
    def index_id; end
  end

  class NamedScope
    extend T::Sig
    include Indexable

    sig { override.returns(String) }
    def index_id
      qualified_name
    end
  end

  class Def
    extend T::Sig
    include Indexable

    sig { override.returns(String) }
    def index_id
      qualified_name
    end
  end

  class Attr
    extend T::Sig
    include Indexable

    sig { override.returns(String) }
    def index_id
      qualified_name
    end
  end

  class Const
    extend T::Sig
    include Indexable

    sig { override.returns(String) }
    def index_id
      qualified_name
    end
  end

  class Send
    extend T::Sig
    include Indexable

    sig { override.returns(String) }
    def index_id
      "#{named_parent_scope&.qualified_name}.#{method}(#{args.join(',')})"
    end
  end
end
