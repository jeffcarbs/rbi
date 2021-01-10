# typed: true
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
      when :module, :class
        visit_scope(node)
      when :def, :defs
        visit_def(node)
      when :casgn
        visit_const_assign(node)
      when :send
        visit_send(node)
      when :block
        visit_sig(node)
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

    sig { params(node: AST::Node).void }
    def visit_scope(node)
      name = T.must(NameBuilder.parse_node(node.children[0]))

      scope = if node.type == :module
        Module.new(name)
      elsif node.type == :class
        superclass = ExpBuilder.build(node.children[1]) if node.children[1]
        if superclass == "T::Struct"
          TStruct.new(name)
        else
          Class.new(name, superclass: superclass)
        end
      else
        raise "Unsupported node #{node.type}"
      end

      @scopes_stack << scope
      @current_scope << scope
      @current_scope = scope
      visit_all(node.children)
      raise "Not the current scope" unless scope == @current_scope
      @scopes_stack.pop
      @current_scope = T.must(@scopes_stack.last)
    end

    # Properties

    sig { params(node: AST::Node).void }
    def visit_const_assign(node)
      @current_scope << Const.new(
        T.must(NameBuilder.parse_node(node)),
        value: ExpBuilder.build(node.children[2])
      )
    end

    sig { params(node: AST::Node).void }
    def visit_def(node)
      is_singleton = node.type == :defs
      params = node.children[is_singleton ? 2 : 1].children.map { |child| visit_param(child) }
      @current_scope << Method.new(
        node.children[is_singleton ? 1 : 0].to_s,
        is_singleton: is_singleton,
        params: params,
      )
    end

    sig { params(node: AST::Node).returns(Param) }
    def visit_param(node)
      case node.type
      when :arg
        Arg.new(node.children[0].to_s)
      when :optarg
        OptArg.new(node.children[0].to_s, value: ExpBuilder.build(node.children[1]))
      when :restarg
        RestArg.new(node.children[0].to_s)
      when :kwarg
        KwArg.new(node.children[0].to_s)
      when :kwoptarg
        KwOptArg.new(node.children[0].to_s, value: ExpBuilder.build(node.children[1]))
      when :kwrestarg
        KwRestArg.new(node.children[0].to_s)
      when :blockarg
        BlockArg.new(node.children[0].to_s)
      else
        raise "Unkown arg type #{node.type}"
      end
    end

    sig { params(node: AST::Node).void }
    def visit_send(node)
      method_name = node.children[1]
      case method_name
      when :attr_reader
        symbols = node.children[2..-1].map { |child| child.children[0] }
        attr = AttrReader.new(*symbols)
        @current_scope << attr
      when :attr_writer
        symbols = node.children[2..-1].map { |child| child.children[0] }
        attr = AttrWriter.new(*symbols)
        @current_scope << attr
      when :attr_accessor
        symbols = node.children[2..-1].map { |child| child.children[0] }
        attr = AttrAccessor.new(*symbols)
        @current_scope << attr
      when :include
        names = node.children[2..-1].map { |child| NameBuilder.parse_node(child) }
        @current_scope << Include.new(*names)
      when :extend
        names = node.children[2..-1].map { |child| NameBuilder.parse_node(child) }
        @current_scope << Extend.new(*names)
      when :prepend
        names = node.children[2..-1].map { |child| NameBuilder.parse_node(child) }
        @current_scope << Prepend.new(*names)
      when :abstract!
        @current_scope << Abstract.new
      when :sealed!
        @current_scope << Sealed.new
      when :interface!
        @current_scope << Interface.new
      when :mixes_in_class_methods
        names = node.children[2..-1].map { |child| NameBuilder.parse_node(child) }
        @current_scope << MixesInClassMethods.new(*names)
      when :public
        @current_scope << Public.new
      when :protected
        @current_scope << Protected.new
      when :private
        @current_scope << Private.new
      when :prop
        visit_prop(node) do |name, type, default_value|
          @current_scope << TProp.new(name, type: type, default: default_value)
        end
      when :const
        visit_prop(node) do |name, type, default_value|
          @current_scope << TConst.new(name, type: type, default: default_value)
        end
      else
        raise "Unsupported call type #{method_name}"
      end
    end

    sig do
      params(
        node: AST::Node,
        block: T.proc.params(name: String, type: String, default_value: T.nilable(String)).void
      ).void
    end
    def visit_prop(node, &block)
      name = node.children[2].children[0].to_s
      type = ExpBuilder.build(node.children[3])
      has_default = node.children[4]
        &.children&.fetch(0, nil)
        &.children&.fetch(0, nil)
        &.children&.fetch(0, nil) == :default
      default_value = if has_default
        ExpBuilder.build(node.children.fetch(4, nil)
          &.children&.fetch(0, nil)
          &.children&.fetch(1, nil))
      end
      block.call(name, T.must(type), default_value)
    end

    sig { params(node: AST::Node).void }
    def visit_sig(node)
      sig = SigBuilder.build(node)
      return nil unless sig
      @current_scope << sig
    end
  end
end
