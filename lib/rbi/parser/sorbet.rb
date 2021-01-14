# typed: strict
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

        sig { params(obj: T.nilable(T::Hash[String, T.untyped])).void }
        def visit(obj)
          return unless obj.is_a?(Hash)
          case obj["type"]
          when "Assign"
            visit_const(obj)
          when "Begin"
            visit_all(obj["stmts"])
          when "Block"
            visit_sig(obj)
          when "DefMethod", "DefS"
            visit_def(obj)
          when "Module", "Class"
            visit_scope(obj)
          when "Send"
            visit_send(obj)
          else
            raise "Unkown node type #{obj}"
          end
        end

        def visit_all(obj)
          return unless obj.is_a?(Array)
          obj.each { |child| visit(child) }
        end

        private

        def visit_const(obj)
          return nil unless obj
          return nil unless obj["lhs"]["type"] == "ConstLhs"
          name = make_name(obj["lhs"])
          # TODO value
          # puts obj
          @current_scope << Const.new(name, value: nil)
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

          obj["body"]&.each do |in_body|
            node = visit(in_body)
            raise unless node.is_a?(InBody)
            scope << node
          end

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
            # TODO
            # puts obj
            name = ""
            type = ""
            default = nil
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
            # TODO
            # puts obj
            name = ""
            type = ""
            default = nil
            @current_scope << TProp.new(name, type: type, default: default)
          when "protected"
            @current_scope << Protected.new
          when "private"
            @current_scope << Private.new
          when "sealed!"
            @current_scope << Sealed.new
          else
            # do nothing
          end
        end

        def visit_sig(obj)
          return nil unless obj &&
            obj["type"] == "Block" &&
            obj["receiver"] == nil &&
            obj["method"] == nil
          @current_scope << Sig.new
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
            return "::#{obj["name"]}" if scope["type"] == "Cbase"
            return "#{make_name(scope)}::#{obj["name"]}"
          when "Symbol"
            return obj["val"]
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
            # TODO value
            # puts obj
            OptArg.new(name, value: nil)
          when "Restarg"
            RestArg.new(name)
          when "Kwarg"
            KwArg.new(name)
          when "Kwoptarg"
            # TODO value
            # puts obj
            KwOptArg.new(name, value: nil)
          when "Kwrestarg"
            KwRestArg.new(name)
          when "Blockarg"
            BlockArg.new(name)
          else
            raise "Unkown arg type #{obj}"
          end
        end
      end
    end
  end
end
