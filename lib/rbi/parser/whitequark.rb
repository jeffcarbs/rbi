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
        node, comments = ::Parser::CurrentRuby.parse_with_comments(string)
        parse_ast("-", node, comments)
      rescue ::Parser::SyntaxError => e
        raise Error.new(e.message, loc: nil)
      end

      sig { override.params(path: String).returns(T.nilable(RBI)) }
      def parse_file(path)
        node, comments = ::Parser::CurrentRuby.parse_file_with_comments(path)
        parse_ast(path, node, comments)
      rescue ::Parser::SyntaxError => e
        raise Error.new(e.message, loc: nil)
      end

      private

      sig do
        params(
          path: String, node:
          T.nilable(AST::Node),
          comments: T::Array[::Parser::Source::Comment]
        ).returns(T.nilable(RBI))
      end
      def parse_ast(path, node, comments = [])
        rbi = RBI.new
        assoc = ::Parser::Source::Comment.associate_locations(node, comments)
        builder = Builder.new(path, rbi.root, comments: assoc)
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
          when :self
            names << "self"
          when :cbase
            names << ""
          end
        end
      end

      class ExpBuilder < SExpVisitor
        extend T::Sig

        sig { params(node: T.nilable(AST::Node), in_send: T::Boolean).returns(T.nilable(String)) }
        def self.visit(node, in_send: false)
          v = ExpBuilder.new(in_send: in_send)
          v.visit(node)
          out = v.out.string
          return nil if out.empty?
          out
        end

        sig { returns(StringIO) }
        attr_accessor :out

        sig { params(in_send: T::Boolean).void }
        def initialize(in_send: false)
          super()
          @in_send = in_send
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
            recv = node.children[1].to_s
            @out << recv
            params = node.children[2..-1]
            unless params.empty?
              @out << "("
              params.each_with_index do |child, index|
                @out << ", " if index > 0
                @out << ExpBuilder.visit(child, in_send: child.type == :hash)
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
          when :array
            @out << "["
            node.children.each_with_index do |child, index|
              @out << ", " if index > 0
              visit(child)
            end
            @out << "]"
          when :hash
            @out << "{" unless @in_send
            node.children.each_with_index do |child, index|
              @out << ", " if index > 0
              visit(child)
            end
            @out << "}" unless @in_send
          when :pair
            @out << "#{node.children[0].children[0]}: "
            visit(node.children[1])
          when :str
            @out << "\"#{node.children[0]}\""
          when :sym
            @out << ":#{node.children[0]}"
          when :int, :float
            @out << node.children[0]
          when :nil
            @out << "nil"
          when :self
            @out << "self"
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
          builder = case name
          when :abstract
            Sig::Abstract.new
          when :override
            Sig::Override.new
          when :overridable
            Sig::Overridable.new
          when :checked
            symbols = node.children[2..-1].map { |child| child.children[0] }
            Sig::Checked.new(symbols)
          when :type_parameters
            symbols = node.children[2..-1].map { |child| child.children[0] }
            Sig::TypeParameters.new(symbols)
          when :params
            Sig::Params.new(node.children[2].children.map do |child|
              name = child.children[0].children[0].to_s
              type = ExpBuilder.visit(child.children[1])
              Sig::Param.new(name, type: type)
            end)
          when :returns
            Sig::Returns.new(ExpBuilder.visit(node.children[2]))
          when :void
            Sig::Void.new
          else
            raise "#{node.location.line}: Unhandled #{node}"
          end
          @current << builder
        end
      end

      class Builder < SExpVisitor
        extend T::Sig

        sig do
          params(
            file: String,
            root: Scope,
            comments: T.nilable(T::Hash[::Parser::Source::Map, T::Array[::Parser::Source::Comment]])
          ).void
        end
        def initialize(file, root, comments: nil)
          super()
          @file = file
          @root = root
          @comments = comments
          @scopes_stack = T.let([root], T::Array[Scope])
          @current_scope = T.let(root, Scope)
        end

        sig { override.params(node: T.nilable(Object)).void }
        def visit(node)
          return unless node.is_a?(AST::Node)
          case node.type
          when :module, :class, :sclass
            visit_scope(node)
          when :def
            visit_def(node)
          when :defs
            visit_sdef(node)
          when :casgn
            visit_const_assign(node)
          when :send
            visit_send(node) if !node.children[0] || node.children[0].type == :self
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

          scope = case node.type
          when :module
            Module.new(name)
          when :class
            superclass = ExpBuilder.visit(node.children[1]) if node.children[1]
            Class.new(name, superclass: superclass)
          when :sclass
            SClass.new
          else
            raise "Unsupported node #{node.type}"
          end
          scope.loc = node_loc(node)
          scope.comments = node_comments(node)

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
          const = Const.new(
            T.must(NameVisitor.visit(node)),
            value: ExpBuilder.visit(node.children[2])
          )
          const.loc = node_loc(node)
          const.comments = node_comments(node)
          @current_scope << const
        end

        sig { params(node: AST::Node).void }
        def visit_def(node)
          meth = Def.new(node.children[0].to_s,
            params: node.children[1].children.map { |child| visit_param(child) },
          )
          meth.loc = node_loc(node)
          meth.comments = node_comments(node)
          @current_scope << meth
        end

        sig { params(node: AST::Node).void }
        def visit_sdef(node)
          meth = DefS.new(node.children[1].to_s,
            params: node.children[2].children.map { |child| visit_param(child) },
          )
          meth.loc = node_loc(node)
          meth.comments = node_comments(node)
          @current_scope << meth
        end

        sig { params(node: AST::Node).returns(Param) }
        def visit_param(node)
          param = case node.type
          when :arg
            Param.new(node.children[0].to_s)
          when :optarg
            OptParam.new(node.children[0].to_s, value: ExpBuilder.visit(node.children[1]))
          when :restarg
            RestParam.new(node.children[0].to_s)
          when :kwarg
            KwParam.new(node.children[0].to_s)
          when :kwoptarg
            KwOptParam.new(node.children[0].to_s, value: ExpBuilder.visit(node.children[1]))
          when :kwrestarg
            KwRestParam.new(node.children[0].to_s)
          when :blockarg
            BlockParam.new(node.children[0].to_s)
          else
            raise "Unkown arg type #{node.type}"
          end
          param.loc = node_loc(node)
          param
        end

        sig { params(node: AST::Node).void }
        def visit_send(node)
          method_name = node.children[1]
          send = case method_name
          when :attr_reader
            symbols = node.children[2..-1].map { |child| child.children[0] }
            AttrReader.new(*symbols)
          when :attr_writer
            symbols = node.children[2..-1].map { |child| child.children[0] }
            AttrWriter.new(*symbols)
          when :attr_accessor
            symbols = node.children[2..-1].map { |child| child.children[0] }
            AttrAccessor.new(*symbols)
          when :include
            names = node.children[2..-1].map { |child| NameVisitor.visit(child) }
            Include.new(*names)
          when :extend
            names = node.children[2..-1].map { |child| NameVisitor.visit(child) }
            Extend.new(*names)
          when :prepend
            names = node.children[2..-1].map { |child| NameVisitor.visit(child) }
            Prepend.new(*names)
          when :abstract!
            Abstract.new
          when :sealed!
            Sealed.new
          when :interface!
            Interface.new
          when :mixes_in_class_methods
            names = node.children[2..-1].map { |child| NameVisitor.visit(child) }
            MixesInClassMethods.new(*names)
          when :public
            Public.new
          when :protected
            Protected.new
          when :private
            Private.new
          when :prop
            visit_prop(node) do |name, type, default_value|
              TProp.new(name, type: type, default: default_value)
            end
          when :const
            visit_prop(node) do |name, type, default_value|
              TConst.new(name, type: type, default: default_value)
            end
          end
          return unless send
          send.loc = node_loc(node)
          send.comments = node_comments(node)
          @current_scope << send
        end

        sig do
          params(
            node: AST::Node,
            block: T.proc.params(name: String, type: String, default_value: T.nilable(String)).returns(Stmt)
          ).returns(Stmt)
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
          sig.loc = node_loc(node)
          sig.comments = node_comments(node)
          @current_scope << sig
        end

        sig { params(node: AST::Node).returns(Loc) }
        def node_loc(node)
          rbi_loc(node.location)
        end

        sig { params(node: AST::Node).returns(T::Array[Comment]) }
        def node_comments(node)
          return [] unless @comments
          comments = @comments[node.location]
          return [] unless comments
          comments.map { |comment| Comment.new(comment.text, loc: rbi_loc(comment.loc)) }
        end

        sig { params(loc: ::Parser::Source::Map).returns(Loc) }
        def rbi_loc(loc)
          Loc.new(@file, Range.new(Pos.new(loc.line, loc.column), Pos.new(loc.last_line, loc.last_column)))
        end
      end
    end
  end
end
