# typed: true
# frozen_string_literal: true

class RBI
  class SigBuilder
    extend T::Sig

    def self.parse(string)
      node = Parser.parse_string(string)
      return nil unless node
      build(node)
    end

    sig { params(node: AST::Node).returns(T.nilable(Sig)) }
    def self.build(node)
      return nil unless node.type == :block && node.children[0].children[1] == :sig
      v = SigBuilder.new
      v.visit_all(node.children[2..-1])
      v.current
    end

    sig { returns(Sig) }
    attr_accessor :current

    sig { void }
    def initialize
      @current = T.let(Sig.new, Sig)
    end

    sig { params(nodes: T::Array[AST::Node]).void }
    def visit_all(nodes)
      nodes.each { |node| visit(node) }
    end

    sig { params(node: T.nilable(AST::Node)).void }
    def visit(node)
      return unless node
      case node.type
      when :send
        visit_send(node)
      end
    end

    def visit_send(node)
      visit(node.children[0]) if node.children[0]
      name = node.children[1]
      case name
      when :void
        @current << Returns.new("void")
      when :returns
        @current << Returns.new(ExpBuilder.build(node.children[2]))
      when :params
        @current << Params.new(node.children[2].children.map do |child|
          name = child.children[0].children[0].to_s
          type = ExpBuilder.build(child.children[1])
          Param.new(name, type: type)
        end)
      when :abstract
        @current << SAbstract.new
      end
    end
  end
end
