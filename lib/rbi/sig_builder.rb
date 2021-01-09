# typed: true
# frozen_string_literal: true

class RBI
  class Sig
    extend T::Sig

    sig { params(node: AST::Node).returns(T.nilable(Sig)) }
    def self.from_node(node)
      return nil unless node.type == :block && node.children[0].children[1] == :sig
      v = SigBuilder.new
      v.visit(node)
      v.current
    end

    def self.from_string(string)
      node = Parser.parse_string(string)
      return nil unless node
      from_node(node)
    end
  end

  class SigBuilder
    extend T::Sig

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
        @current.returns = "void"
      puts node
      puts "----"
        visit_all(node.children)
      when :returns
        @current.returns = node.children[2].to_s
      puts node
      puts "----"
        visit_all(node.children)
      when :params
        @current.params << Arg.new("P")
        visit_all(node.children)
      when :abstract
        @current.is_abstract = true
        visit_all(node.children)
      end
    end
  end
end
