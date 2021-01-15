# typed: ignore
# frozen_string_literal: true

class RBI
  def index
    v = IndexVisitor.new
    v << self
    v.index
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

  class IndexVisitor
    attr_reader :index

    def initialize
      @index = Index.new
      @scopes_stack = []
    end

    def <<(rbi)
      visit(rbi.root)
    end

    private

    def current_scope
      @scopes_stack.last
    end

    def root_scope?
      @scopes_stack.size == 1
    end

    def parent_scope
      return nil if root_scope?
      @scopes_stack[-2]
    end

    def current_namespace
      @scopes_stack[1..-1].map(&:name).prepend("").join("::")
    end

    def visit(node)
      case node
      when Scope
        visit_scope(node)
      when Def
        visit_def(node)
      when Send
        visit_send(node)
      else
        raise "Unhandled #{node}"
      end
    end

    def visit_all(nodes)
      nodes.each { |node| visit(node) }
    end

    def visit_scope(scope)
      @scopes_stack << scope
      visit_all(scope.body)
      @scopes_stack.pop
    end

    def visit_const(node)
      @index["#{current_namespace}::#{name}"] << node
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
  end

  def merge(other)
    v = Rewriter::Merge.new
    # TODO: index
    # TODO merge defs by keys and warn
    # TODO sort
    v.merge(self)
    v.merge(other)
    v.rbi
  end

  def hierarchize
    rbi = RBI.new
    # TODO: index
    # TODO merge defs by keys and warn
    # TODO visit namespaces
    # TODO sort
    # visit
    # unroll names
    # move children
    rbi
  end

  def sort
    rbi = RBI.new
    # visit
    # unroll names
    # move children
    rbi
  end

  module Rewriter
    class Merge
      attr_reader :rbi

      def initialize
        @rbi = RBI.new
        @scopes = {}
        @scopes_stack = [rbi.root]
      end

      def merge(rbi)
        visit(rbi.root)
      end

      private

      def visit(node)
        case node
        when Scope
          visit_scope(node)
        when Stmt
          visit_body(node)
        else
          raise "Unhandled #{node}"
        end
      end

      def visit_all(nodes)
        nodes.each { |node| visit(node) }
      end

      def visit_scope(scope)
        @scopes_stack << scope
        visit_all(scope.body)
        @scopes_stack.pop
      end

      def visit_body(body)
      end
    end
  end

  # TODO: add sigs
  # TODO add doc
  # TODO split? extract?
  # TODO template sig
  #
  # TODO checkers

  # class Rewriter
  # extend T::Sig
  # extend T::Helpers
  #
  # abstract!
  #
  # sig { abstract.params(rbi: RBI).returns(RBI) }
  # def rewriter(rbi); end
  # end
end
