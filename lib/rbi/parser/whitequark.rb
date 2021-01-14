# typed: strict
# frozen_string_literal: true

class RBI
  module Parser
    class Whitequark
      extend T::Sig
      include Parser

      # opt-in to most recent AST format:
      ::Parser::Builders::Default.emit_lambda   = true
      ::Parser::Builders::Default.emit_procarg0 = true
      ::Parser::Builders::Default.emit_encoding = true
      ::Parser::Builders::Default.emit_index    = true

      sig { override.params(string: String).returns(T.nilable(RBI)) }
      def parse_string(string)
        node = ::Parser::CurrentRuby.parse(string)
        parse_ast(node)
      end

      sig { override.params(path: String).returns(T.nilable(RBI)) }
      def parse_file(path)
        node = ::Parser::CurrentRuby.parse_file(path)
        parse_ast(node)
      end

      private

      sig { params(node: T.nilable(AST::Node)).returns(T.nilable(RBI)) }
      def parse_ast(node)
        rbi = RBI.new
        builder = Builder.new(rbi.root)
        builder.visit(node)
        rbi
      end

      class SExpVisitor
        extend T::Helpers
        extend T::Sig

        abstract!

        sig { params(nodes: T::Array[AST::Node]).void }
        def visit_all(nodes)
          nodes.each { |node| visit(node) }
        end

        sig { abstract.params(node: T.nilable(AST::Node)).void }
        def visit(node); end
      end

      class NameVisitor < SExpVisitor
        extend T::Sig

        sig { params(node: T.nilable(AST::Node)).returns(T.nilable(String)) }
        def self.visit(node)
          v = NameVisitor.new
          v.visit(node)
          return nil if v.names.empty?
          v.names.join("::")
        end

        sig { returns(T::Array[String]) }
        attr_accessor :names

        sig { void }
        def initialize
          super
          @names = T.let([], T::Array[String])
        end

        sig { override.params(node: T.nilable(AST::Node)).void }
        def visit(node)
          return unless node
          case node.type
          when :const, :casgn, :send
            visit(node.children[0])
            @names << node.children[1].to_s
          when :index
            visit(node.children[0])
          when :cbase
            names << ""
          end
        end
      end

      class ExpBuilder < SExpVisitor
        extend T::Sig

        sig { params(node: T.nilable(AST::Node)).returns(T.nilable(String)) }
        def self.visit(node)
          v = ExpBuilder.new
          v.visit(node)
          out = v.out.string
          return nil if out.empty?
          out
        end

        sig { returns(StringIO) }
        attr_accessor :out

        sig { void }
        def initialize
          super
          @out = T.let(StringIO.new, StringIO)
        end

        sig { override.params(node: T.nilable(AST::Node)).void }
        def visit(node)
          return unless node
          case node.type
          when :send
            if node.children[0]
              visit(node.children[0])
              @out << "."
            end
            @out << node.children[1].to_s
            params = node.children[2..-1]
            unless params.empty?
              @out << "("
              params.each_with_index do |child, index|
                @out << ", " if index > 0
                visit(child)
              end
              @out << ")"
            end
          when :const
            if node.children[0]
              visit(node.children[0])
              @out << "::"
            end
            @out << node.children[1].to_s
          when :index
            visit(node.children[0])
            @out << "["
            node.children[1..-1].each_with_index do |child, index|
              @out << ", " if index > 0
              visit(child)
            end
            @out << "]"
          when :str
            @out << "\"#{node.children[0]}\""
          when :int
            @out << node.children[0]
          when :nil
            @out << "nil"
          when :cbase
            @out << ""
          else
            @out << node.to_s
          end
        end
      end

      class SigBuilder < SExpVisitor
        extend T::Sig

        sig { params(string: String).returns(T.nilable(Sig)) }
        def self.parse(string)
          build(::Parser::CurrentRuby.parse(string))
        end

        sig { params(node: T.nilable(AST::Node)).returns(T.nilable(Sig)) }
        def self.build(node)
          return nil unless node
          return nil unless node.type == :block && node.children[0].children[1] == :sig
          v = SigBuilder.new
          v.visit_all(node.children[2..-1])
          v.current
        end

        sig { returns(Sig) }
        attr_accessor :current

        sig { void }
        def initialize
          super
          @current = T.let(Sig.new, Sig)
        end

        sig { override.params(node: T.nilable(AST::Node)).void }
        def visit(node)
          return unless node
          case node.type
          when :send
            visit_send(node)
          end
        end

        sig { params(node: AST::Node).void }
        def visit_send(node)
          visit(node.children[0]) if node.children[0]
          name = node.children[1]
          case name
          when :void
            @current << Returns.new("void")
          when :returns
            @current << Returns.new(ExpBuilder.visit(node.children[2]))
          when :params
            @current << Params.new(node.children[2].children.map do |child|
              name = child.children[0].children[0].to_s
              type = ExpBuilder.visit(child.children[1])
              Param.new(name, type: type)
            end)
          when :abstract
            @current << SAbstract.new
          end
        end
      end

      class Builder < SExpVisitor
        extend T::Sig

        sig { params(root: Scope).void }
        def initialize(root)
          super()
          @root = root
          @scopes_stack = T.let([root], T::Array[Scope])
          @current_scope = T.let(root, Scope)
        end

        sig { override.params(node: T.nilable(Object)).void }
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

        private

        # Scopes

        sig { params(node: AST::Node).void }
        def visit_scope(node)
          name = T.must(NameVisitor.visit(node.children[0]))

          scope = if node.type == :module
            Module.new(name)
          elsif node.type == :class
            superclass = ExpBuilder.visit(node.children[1]) if node.children[1]
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
            T.must(NameVisitor.visit(node)),
            value: ExpBuilder.visit(node.children[2])
          )
        end

        sig { params(node: AST::Node).void }
        def visit_def(node)
          is_singleton = node.type == :defs
          params = node.children[is_singleton ? 2 : 1].children.map { |child| visit_param(child) }
          @current_scope << Def.new(
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
            OptArg.new(node.children[0].to_s, value: ExpBuilder.visit(node.children[1]))
          when :restarg
            RestArg.new(node.children[0].to_s)
          when :kwarg
            KwArg.new(node.children[0].to_s)
          when :kwoptarg
            KwOptArg.new(node.children[0].to_s, value: ExpBuilder.visit(node.children[1]))
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
            names = node.children[2..-1].map { |child| NameVisitor.visit(child) }
            @current_scope << Include.new(*names)
          when :extend
            names = node.children[2..-1].map { |child| NameVisitor.visit(child) }
            @current_scope << Extend.new(*names)
          when :prepend
            names = node.children[2..-1].map { |child| NameVisitor.visit(child) }
            @current_scope << Prepend.new(*names)
          when :abstract!
            @current_scope << Abstract.new
          when :sealed!
            @current_scope << Sealed.new
          when :interface!
            @current_scope << Interface.new
          when :mixes_in_class_methods
            names = node.children[2..-1].map { |child| NameVisitor.visit(child) }
            @current_scope << MixesInClassDefs.new(*names)
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
          type = ExpBuilder.visit(node.children[3])
          has_default = node.children[4]
            &.children&.fetch(0, nil)
            &.children&.fetch(0, nil)
            &.children&.fetch(0, nil) == :default
          default_value = if has_default
            ExpBuilder.visit(node.children.fetch(4, nil)
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
  end
end
