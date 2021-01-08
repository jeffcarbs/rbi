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
        visit_def(node)
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
      method = case node.type
      when :def
        Method.new(
          node.children[0].to_s,
          is_singleton: false,
          params: visit_params(node.children[1].children),
        )
      when :defs
        Method.new(
          node.children[1].to_s,
          is_singleton: true,
          params: visit_params(node.children[2].children),
        )
      else
        raise "Unkown method type"
      end
      @current_scope << method
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
        Arg.new(node.children.first.to_s)
      when :optarg
        OptArg.new(node.children.first.to_s, value: node.children[1].children.first.to_s)
      when :restarg
        RestArg.new(node.children.first.to_s)
      when :kwarg
        KwArg.new(node.children.first.to_s)
      when :kwoptarg
        KwOptArg.new(node.children.first.to_s, value: node.children[1].children.first.to_s)
      when :kwrestarg
        KwRestArg.new(node.children.first.to_s)
      when :blockarg
        BlockArg.new(node.children.first.to_s)
      else
        raise "Unkown arg type #{node.type}"
      end
    end

    sig { params(node: AST::Node).void }
    def visit_send(node)
      kind = node.children[1]
      if kind == :sig
        visit_sig(node)
        return
      end

      case kind
      when :attr_reader
        symbols = node.children[2..-1].map { |child| child.children.first }
        attr = AttrReader.new(*symbols)
        @current_scope << attr
      when :attr_writer
        symbols = node.children[2..-1].map { |child| child.children.first }
        attr = AttrWriter.new(*symbols)
        @current_scope << attr
      when :attr_accessor
        symbols = node.children[2..-1].map { |child| child.children.first }
        attr = AttrAccessor.new(*symbols)
        @current_scope << attr
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
      when :public
        @current_scope << Public.new
      when :protected
        @current_scope << Protected.new
      when :private
        @current_scope << Private.new
      end
    end

    sig { params(_node: AST::Node).void }
    def visit_sig(_node)
      @current_scope << Sig.new # TODO: parse sig
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
