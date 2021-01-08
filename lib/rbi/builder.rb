# typed: strict
# frozen_string_literal: true

class RBI
  extend T::Sig

  sig { params(string: String).returns(RBI) }
  def self.from_string(string)
    node = Parser.parse_string(string)
    Builder.build(node)
  end

  sig { params(path: String).returns(RBI) }
  def self.from_file(path)
    node = Parser.parse_file(path)
    Builder.build(node)
  end

  class Builder
    extend T::Sig

    sig { params(node: T.nilable(AST::Node)).returns(RBI) }
    def self.build(node)
      rbi = RBI.new
      builder = Builder.new(rbi.root)
      builder.visit(node)
      rbi
    end

    sig { params(root: Scope).void }
    def initialize(root)
      @root = root
      @scopes_stack = T.let([root], T::Array[Scope])
      @current_scope = T.let(root, Scope)
      @last_sig = T.let(nil, T.nilable(Sig))
    end

    sig { params(node: T.nilable(Object)).void }
    def visit(node)
      return unless node.is_a?(AST::Node)

      case node.type
      when :module
        visit_module(node)
      when :class
        visit_class(node)
      when :def
        visit_def(node)
      when :defs
        visit_defs(node)
      when :casgn
        visit_const_assign(node)
      when :send
        visit_send(node)
      else
        visit_all(node.children)
      end
    end

    sig { params(nodes: T::Array[AST::Node]).void }
    def visit_all(nodes)
      nodes.each { |node| visit(node) }
    end

    private

    # Scopes

    sig { params(scope: Scope).void }
    def enter_scope(scope)
      @scopes_stack << scope
      @current_scope << scope
      @current_scope = scope
    end

    sig { params(scope: Scope).void }
    def exit_scope(scope)
      raise "Not the current scope" unless scope == @current_scope
      @scopes_stack.pop
      @current_scope = T.must(@scopes_stack.last)
    end

    sig { params(node: AST::Node).void }
    def visit_module(node)
      name = visit_name(node.children.first)
      mod = Module.new(name)

      enter_scope(mod)
      visit_all(node.children)
      exit_scope(mod)
    end

    sig { params(node: AST::Node).void }
    def visit_class(node)
      name = visit_name(node.children.first)
      superclass = visit_name(node.children[1]) if node.children[1]
      klass = Class.new(name, superclass: superclass)

      enter_scope(klass)
      visit_all(node.children)
      exit_scope(klass)
    end

    # Properties

    sig { params(node: AST::Node).void }
    def visit_const_assign(node)
      name = if node.children[0]
        visit_name(node.children[0])
      else
        node.children[1].to_s
      end
      # TODO: parse value
      @current_scope << Const.new(name)
    end

    sig { params(node: AST::Node).void }
    def visit_def(node)
      name = node.children.first
      params = visit_params(node.children[1].children)
      @current_scope << Method.new(name.to_s, is_singleton: false, params: params)
    end

    sig { params(node: AST::Node).void }
    def visit_defs(node)
      name = node.children[1]
      params = visit_params(node.children[2].children)
      @current_scope << Method.new(name.to_s, is_singleton: true, params: params)
    end

    sig { params(nodes: T.nilable(T::Array[AST::Node])).returns(T::Array[Param]) }
    def visit_params(nodes)
      return [] unless nodes
      nodes.map { |node| visit_param(node) }
    end

    sig { params(node: AST::Node).returns(Param) }
    def visit_param(node)
      case node.type
      when :arg
        Param.new(node.children.first.to_s)
      when :restarg
        Param.new(node.children.first.to_s, is_rest: true)
      when :optarg
        Param.new(node.children.first.to_s, value: node.children[1].children.first.to_s)
      when :blockarg
        # TODO
        Param.new(node.children.first.to_s)
      when :kwarg
        Param.new(node.children.first.to_s, is_keyword: true)
      when :kwoptarg
        Param.new(node.children.first.to_s, is_keyword: true, value: node.children[1].children.first.to_s)
      when :kwrestarg
        Param.new(node.children.first.to_s, is_keyword: true, is_rest: true)
      else
        raise "Unkown arg type #{node.type}"
      end
    end

    sig { params(node: AST::Node).void }
    def visit_send(node)
      case node.children[1]
      when :attr_reader
        symbols = node.children[2..-1].map { |child| child.children.first }
        @current_scope << AttrReader.new(*symbols)
      when :attr_writer
        symbols = node.children[2..-1].map { |child| child.children.first }
        @current_scope << AttrWriter.new(*symbols)
      when :attr_accessor
        symbols = node.children[2..-1].map { |child| child.children.first }
        @current_scope << AttrAccessor.new(*symbols)
      when :include
        names = node.children[2..-1].map { |child| visit_name(child) }
        @current_scope << Include.new(*names)
      when :extend
        names = node.children[2..-1].map { |child| visit_name(child) }
        @current_scope << Extend.new(*names)
      when :prepend
        names = node.children[2..-1].map { |child| visit_name(child) }
        @current_scope << Prepend.new(*names)
      when :abstract!
        @current_scope << Abstract.new
      when :sealed!
        @current_scope << Sealed.new
      when :interface!
        @current_scope << Interface.new
      when :mixes_in_class_methods
        names = node.children[2..-1].map { |child| visit_name(child) }
        @current_scope << MixesInClassMethods.new(*names)
      when :sig
        visit_sig(node)
      end
    end

    sig { params(_node: AST::Node).void }
    def visit_sig(_node)
      raise "Already in a sig" if @last_sig
      @last_sig = Sig.new # TODO: parse sig
    end

    # Utils

    sig { params(node: AST::Node).returns(String) }
    def visit_name(node)
      v = ScopeNameVisitor.new
      v.visit(node)
      v.names.join("::")
    end
  end

  class ScopeNameVisitor
    extend T::Sig

    sig { returns(T::Array[String]) }
    attr_accessor :names

    sig { void }
    def initialize
      @names = T.let([], T::Array[String])
    end

    sig { params(node: T.nilable(Object)).void }
    def visit(node)
      return unless node.is_a?(::Parser::AST::Node)
      node.children.each { |child| visit(child) }
      names << node.location.name.source if node.type == :const
    end
  end
end
