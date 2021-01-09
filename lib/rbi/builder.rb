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
      name = visit_name(node.children[0])

      scope = if node.type == :module
        Module.new(name)
      elsif node.type == :class
        superclass = visit_name(node.children[1]) if node.children[1]
        Class.new(name, superclass: superclass)
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
        visit_names(node.children[0...-1]),
        value: visit_value(node.children.last)
      )
    end

    sig { params(node: AST::Node).void }
    def visit_def(node)
      is_singleton = node.type == :defs
      params = node.children[is_singleton ? 2 : 1].children.map { |node| visit_param(node) }
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
        OptArg.new(node.children[0].to_s, value: visit_value(node.children[1]))
      when :restarg
        RestArg.new(node.children[0].to_s)
      when :kwarg
        KwArg.new(node.children[0].to_s)
      when :kwoptarg
        KwOptArg.new(node.children[0].to_s, value: visit_value(node.children[1]))
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
      else
        raise "Unsupported call type #{method_name}"
      end
    end

    sig { params(node: AST::Node).void }
    def visit_sig(node)
      return unless node.children[0]&.children[1] == :sig
      v = SigVisitor.new
      v.visit(node.children[2])
      @current_scope << v.ssig
    end

    # Utils

    sig { params(node: AST::Node).returns(String) }
    def visit_name(node)
      v = NameBuilder.new
      v.visit(node)
      v.names.join("::")
    end

    sig { params(nodes: T::Array[AST::Node]).returns(String) }
    def visit_names(nodes)
      v = NameBuilder.new
      v.visit_all(nodes)
      v.names.join("::")
    end

    sig { params(node: AST::Node).returns(String) }
    def visit_value(node)
      case node.type
      when :str
        "\"#{node.children.map(&:to_s).join(', ')}\""
      when :const
        visit_name(node)
      when :send
        if node.children[0]
          "#{node.children[0]}.#{node.children[1]}"
        else
          node.children[1].to_s
        end
      else
        raise "Unsupported value type #{node.type}"
      end
    end
  end

  # TODO visitor abstract

  class SigVisitor
    extend T::Sig

    sig { returns(Sig) }
    attr_accessor :ssig

    sig { void }
    def initialize
      @ssig = T.let(Sig.new, Sig)
    end

    sig { params(nodes: T::Array[AST::Node]).void }
    def visit_all(nodes)
      nodes.each { |node| visit(node) }
    end

    sig { params(node: T.nilable(Object)).void }
    def visit(node)
      if node.is_a?(AST::Node)
        case node.type
        when :send
          visit_send(node)
        end
      end
    end

    def visit_send(node)
      name = node.children[1]
      # puts name
      case name
      when :void
        ssig.returns = "void"
      puts node
      puts "----"
        visit_all(node.children)
      when :returns
        ssig.returns = node.children[2].to_s
      puts node
      puts "----"
        visit_all(node.children)
      when :params
        ssig.params << Arg.new("P")
        visit_all(node.children)
      when :abstract
        ssig.is_abstract = true
        visit_all(node.children)
      end
    end
  end
end
