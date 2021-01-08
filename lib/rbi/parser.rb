# typed: strict
# frozen_string_literal: true

require 'parser/current'

class RBI
  class Parser
    extend T::Sig

    sig { void }
    def initialize
      # opt-in to most recent AST format:
      ::Parser::Builders::Default.emit_lambda   = true
      ::Parser::Builders::Default.emit_procarg0 = true
      ::Parser::Builders::Default.emit_encoding = true
      ::Parser::Builders::Default.emit_index    = true
    end

    sig { params(paths: String).returns(T::Array[String]) }
    def list_files(*paths)
      files = []
      paths.each do |path|
        unless ::File.exist?(path)
          @logger.warn("can't find `#{path}`.")
          next
        end
        if ::File.directory?(path)
          files = files.concat(Dir.glob(Pathname.new("#{path}/**/*.rbi").cleanpath))
        else
          files << path
        end
      end
      return files.uniq.sort
    end

    sig { params(string: T.nilable(String)).returns(T.nilable(::AST::Node)) }
    def parse_string(string)
      return nil unless string
      ::Parser::CurrentRuby.parse(string)
    end

    sig { params(path: T.nilable(String)).returns(T.nilable(::AST::Node)) }
    def parse_file(path)
      return nil unless path
      ::Parser::CurrentRuby.parse_file(path)
    end

    sig { params(node: T.nilable(Object)).void }
    def visit(node)
      return unless node.is_a?(::Parser::AST::Node)

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

    sig { params(node: AST::Node).void }
    def visit_module(node)
      name = visit_name(node.children.first)
      mod = Module.new(name)
      # TODO
    end

    sig { params(node: AST::Node).void }
    def visit_class(node)
      name = visit_name(node.children.first)
      superclass = visit_name(node.children[1]) if node.children[1]
      klass = Class.new(name, superclass)
      # TODO
    end

    # Properties

    sig { params(node: AST::Node).void }
    def visit_attr(node)
      kind = node.children[1]

      node.children[2..-1].each do |child|
        name = child.children.first.to_s
        AttrDef.new(name)
      end
    end

    sig { params(node: AST::Node).void }
    def visit_const_assign(node)
      name = node.children[1].to_s
      Model::ConstDef.new(loc, last, prop, nil)
    end

    sig { params(node: AST::Node).void }
    def visit_def(node)
      name = node.children.first
      params = node.children[1].children.map { |n| Model::Param.new(n.children.first.to_s) } if node.children[1]
      Model::MethodDef.new(loc, last, prop, false, params, @last_sig)
    end

    sig { params(node: AST::Node).void }
    def visit_defs(node)
      name = node.children[1]
      params = node.children[2].children.map { |n| Model::Param.new(n.children.first.to_s) } if node.children[2]
      Model::MethodDef.new(loc, last, prop, true, params, @last_sig)
    end

    sig { params(node: AST::Node).void }
    def visit_send(node)
      case node.children[1]
      when :attr_reader, :attr_writer, :attr_accessor
        visit_attr(node)
      when :include, :prepend, :extend
        visit_include(node)
      when :sig
        visit_sig(node)
      end
    end

    sig { params(node: AST::Node).void }
    def visit_include(node)
      return unless node.children[2] # TODO
      name = visit_name(node.children[2])
      kind = node.children[1]
      Model::IncludeDef.new(last, name, kind)
    end

    sig { params(node: AST::Node).void }
    def visit_sig(node)
      if @last_sig
        # TODO: print error
        puts "error: already in a sig"
      end
      @last_sig = Model::Sig.new
    end

    # Utils

    sig { params(node: AST::Node).returns(String) }
    def visit_name(node)
      v = ScopeNameVisitor.new
      v.visit(node)
      v.names.join("::")
    end

    sig { returns(String) }
    def current_namespace
      T.must(@stack.last).qname
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
