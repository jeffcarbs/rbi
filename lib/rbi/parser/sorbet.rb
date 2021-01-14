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

        def visit(obj)
          return unless obj.is_a?(Hash)
          case obj["type"]
          when "Begin"
            visit_all(obj["stmts"])
          when "Module", "Class"
            visit_scope(obj)
          else
            raise "Unkown node type #{obj}"
          end
        end

        def visit_all(obj)
          return unless obj.is_a?(Array)
          obj.each { |child| visit(child) }
        end

        def visit_scope(obj)
          scope = case obj["type"]
          when "Module"
            Module.new(visit_const(obj["name"]))
          when "Class"
            Class.new(visit_const(obj["name"]), superclass: visit_const(obj["superclass"]))
          else
            raise "Unsupported node #{node.type}"
          end

          @scopes_stack << scope
          @current_scope << scope
          @current_scope = scope
          # visit_all(node.children)
          raise "Not the current scope" unless scope == @current_scope
          @scopes_stack.pop
          @current_scope = T.must(@scopes_stack.last)
        end

        private

        def visit_const(obj)
          return nil unless obj
          scope = obj["scope"]
          return obj["name"] unless scope
          "#{visit_const(scope)}::#{obj["name"]}"
        end
      end
    end
  end
end
