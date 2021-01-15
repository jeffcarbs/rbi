# typed: ignore
# frozen_string_literal: true

class RBI
  module Parser
    class Sorbet
      extend T::Sig
      include Parser

      sig { override.params(string: String).returns(T.nilable(RBI)) }
      def parse_string(string)
        file = "rbi.compile"
        File.write(file, string)
        rbi = parse_file(file)
        File.delete(file)
        rbi
      end

      sig { override.params(path: String).returns(T.nilable(RBI)) }
      def parse_file(path)
        json, err, status = parse_with_sorbet(path)
        unless status
          raise err
        end
        obj = JSON.parse(json)
        parse_json(obj)
      end

      private

      sig { params(args: String).returns([String, String, T::Boolean]) }
      def parse_with_sorbet(*args)
        run_sorbet("--no-config", "--no-stdlib", "--stop-after=parser", "--print=parse-tree-json-with-locs", *args)
      end

      sig { params(args: String).returns([String, String, T::Boolean]) }
      def run_sorbet(*args)
        out, err, status = Open3.capture3("bundle exec srb tc #{args.join(' ')}")
        [out, err, status.success?]
      end

      def parse_json(obj)
        rbi = RBI.new
        v = JsonVisitor.new(rbi.root)
        if obj.is_a?(Hash)
          v.visit(obj)
        elsif obj.is_a?(Array)
          v.visit_all(obj)
        end
        rbi
      end

      class JsonVisitor
        extend T::Sig

        sig { params(root: Scope).void }
        def initialize(root)
          @root = root
          @scopes_stack = T.let([root], T::Array[Scope])
          @current_scope = T.let(root, Scope)
        end

        # sig { params(obj: T.nilable(T::Hash[String, T.untyped])).returns(T.nilable(Node)) }
        def visit(obj)
          return unless obj.is_a?(Hash)
          case obj["type"]
          when "Assign"
            return visit_const(obj)
          when "Begin"
            return visit_begin(obj)
          when "Block"
            return visit_sig(obj)
          when "DefMethod", "DefS"
            return visit_def(obj)
          when "Module", "Class"
            return visit_scope(obj)
          when "Send"
            return visit_send(obj)
          end
          raise "Unkown node type #{obj}"
        end

        def visit_all(obj)
          return unless obj.is_a?(Array)
          obj.each { |child| visit(child) }
        end

        private

        # sig { params(obj: T.nilable(T::Hash[String, T.untyped])).returns(T.nilable(Begin)) }
        def visit_begin(obj)
          return nil unless obj
          raise "#{obj} is not a Begin node" unless obj["type"] == "Begin"
          # node = Begin.new
          obj["stmts"].each do |stmt|
            visit(stmt)
          # node << stmt if stmt
          end
        end

        def visit_const(obj)
          return nil unless obj
          return nil unless obj["lhs"]["type"] == "ConstLhs"
          name = make_name(obj["lhs"])
          value = ExpBuilder.build(obj["rhs"])
          @current_scope << Const.new(name, value: value)
        end

        def visit_def(obj)
          @current_scope << Def.new(
            obj["name"],
            is_singleton: obj["type"] == "DefS",
            params: make_params(obj["args"]),
          )
        end

        def visit_scope(obj)
          scope = case obj["type"]
          when "Module"
            Module.new(make_name(obj["name"]))
          when "Class"
            Class.new(make_name(obj["name"]), superclass: make_name(obj["superclass"]))
          else
            raise "Unsupported node #{node.type}"
          end

          # body = visit(obj["body"])
          # if body
          # if body.is_a?(Begin)
          # body.stmts.each do |stmt|
          # raise "#{stmt} is not a InScope" unless stmt.is_a?(InScope)
          # scope << stmt
          # end
          # else
          # raise "#{body} is not a InScope" unless body.is_a?(InScope)
          # scope << body
          # end
          # end

          @scopes_stack << scope
          @current_scope << scope
          @current_scope = scope
          visit(obj["body"])
          raise "Not the current scope" unless scope == @current_scope
          @scopes_stack.pop
          @current_scope = T.must(@scopes_stack.last)
        end

        def visit_send(obj)
          case obj["method"]
          when "abstract!"
            @current_scope << Abstract.new
          when "attr_reader"
            names = make_args(obj["args"]).map(&:to_sym)
            @current_scope << AttrReader.new(*names)
          when "attr_writer"
            names = make_args(obj["args"]).map(&:to_sym)
            @current_scope << AttrWriter.new(*names)
          when "attr_accessor"
            names = make_args(obj["args"]).map(&:to_sym)
            @current_scope << AttrAccessor.new(*names)
          when "const"
            name = obj["args"][0]["val"]
            type = ExpBuilder.build(obj["args"][1])
            default = ExpBuilder.build(obj["args"][2]["pairs"][0]["value"])
            @current_scope << TConst.new(name, type: type, default: default)
          when "extend"
            names = make_args(obj["args"])
            @current_scope << Extend.new(*names)
          when "include"
            names = make_args(obj["args"])
            @current_scope << Include.new(*names)
          when "interface!"
            @current_scope << Interface.new
          when "mixes_in_class_methods"
            @current_scope << MixesInClassDefs.new(*make_args(obj["args"]))
          when "public"
            @current_scope << Public.new
          when "prepend"
            names = make_args(obj["args"])
            @current_scope << Prepend.new(*names)
          when "prop"
            name = obj["args"][0]["val"]
            type = ExpBuilder.build(obj["args"][1])
            default = ExpBuilder.build(obj["args"][2]["pairs"][0]["value"])
            @current_scope << TProp.new(name, type: type, default: default)
          when "protected"
            @current_scope << Protected.new
          when "private"
            @current_scope << Private.new
          when "sealed!"
            @current_scope << Sealed.new
          end
        end

        def visit_sig(obj)
          @current_scope << SigBuilder.build(obj)
        end

        def make_args(arr)
          return [] unless arr.is_a?(Array)
          arr.map { |arg| make_name(arg) }
        end

        def make_name(obj)
          return nil unless obj
          case obj["type"]
          when "Const", "ConstLhs"
            scope = obj["scope"]
            return obj["name"] unless scope
            return "::#{obj['name']}" if scope["type"] == "Cbase"
            "#{make_name(scope)}::#{obj['name']}"
          when "Symbol"
            obj["val"]
          else
            raise "Can't make name from #{obj}"
          end
        end

        def make_params(obj)
          return [] unless obj
          obj["args"].map { |param| make_param(param) }
        end

        def make_param(obj)
          name = obj["name"]
          case obj["type"]
          when "Arg"
            Arg.new(name)
          when "Optarg"
            default = obj["default_"]
            value = ExpBuilder.build(default) if default
            OptArg.new(name, value: value)
          when "Restarg"
            RestArg.new(name)
          when "Kwarg"
            KwArg.new(name)
          when "Kwoptarg"
            default = obj["default_"]
            value = ExpBuilder.build(default) if default
            KwOptArg.new(name, value: value)
          when "Kwrestarg"
            KwRestArg.new(name)
          when "Blockarg"
            BlockArg.new(name)
          else
            raise "Unkown arg type #{obj}"
          end
        end

        class SigBuilder
          extend T::Sig

          sig { params(node: T::Hash[String, T.untyped]).returns(T.nilable(Sig)) }
          def self.build(node)
            return nil unless node
            raise unless node["type"] == "Block" && node["send"]["method"] == "sig"
            v = SigBuilder.new
            v.visit(node["body"])
            v.current
          end

          sig { returns(Sig) }
          attr_accessor :current

          sig { void }
          def initialize
            super
            @current = T.let(Sig.new, Sig)
          end

          def visit(node)
            return unless node
            case node["type"]
            when "Send"
              visit_send(node)
            end
          end

          def visit_send(node)
            visit(node["receiver"]) if node["receiver"]
            name = node["method"]
            case name
            when "void"
              @current << Returns.new("void")
            when "returns"
              @current << Returns.new(ExpBuilder.build(node["args"][0]))
            when "params"
              @current << Params.new(node["args"][0]["pairs"].map do |child|
                name = child["key"]["val"]
                type = ExpBuilder.build(child["value"])
                Param.new(name, type: type)
              end)
            when "abstract"
              @current << SAbstract.new
            end
          end
        end

        class ExpBuilder
          extend T::Sig

          sig { params(node: T::Hash[String, T.untyped]).returns(T.nilable(String)) }
          def self.build(node)
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

          def visit(node)
            return unless node
            case node["type"]
            when "Send"
              name = node["method"]
              recv = node["receiver"]
              params = node["args"]
              if recv
                visit(recv)
                @out << "." unless name == "[]"
              end
              @out << name unless name == "[]"
              unless params.empty?
                @out << (name == "[]" ? "[" : "(")
                params.each_with_index do |child, index|
                  @out << ", " if index > 0
                  visit(child)
                end
                @out << (name == "[]" ? "]" : ")")
              end
            when "Const"
              recv = node["scope"]
              if recv
                visit(recv)
                @out << "::"
              end
              @out << node["name"]
            when :index
              visit(node.children[0])
              @out << "["
              node.children[1..-1].each_with_index do |child, index|
                @out << ", " if index > 0
                visit(child)
              end
              @out << "]"
            when "Array"
              @out << "["
              node["elts"].each_with_index do |child, index|
                @out << ", " if index > 0
                visit(child)
              end
              @out << "]"
            when "Hash"
              # puts node
              @out << "{"
              node["pairs"].each_with_index do |child, index|
                @out << ", " if index > 0
                visit(child["key"])
                @out << ": "
                visit(child["value"])
              end
              @out << "}"
            when "String"
              @out << "\"#{node['val']}\""
            when "Symbol"
              @out << node["val"].to_sym
            when "Integer", "Float"
              @out << node["val"]
            when "Nil"
              @out << "nil"
            when :cbase
              @out << ""
            else
              @out << node.to_s
            end
          end
        end
      end
    end
  end
end
