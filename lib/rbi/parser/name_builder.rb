 # typed: true
# frozen_string_literal: true

class RBI
  class NameBuilder
    extend T::Sig

    sig { params(string: String).returns(T.nilable(String)) }
    def self.parse_string(string)
      node = Parser.parse_string(string)
      return nil unless node
      parse_node(node)
    end

    sig { params(node: AST::Node).returns(T.nilable(String)) }
    def self.parse_node(node)
      v = NameBuilder.new
      v.visit(node)
      return nil if v.names.empty?
      v.names.join("::")
    end

    sig { returns(T::Array[String]) }
    attr_accessor :names

    sig { void }
    def initialize
      @names = T.let([], T::Array[String])
    end

    sig { params(nodes: T::Array[AST::Node]).void }
    def visit_all(nodes)
      nodes.each { |node| visit(node) }
    end

    sig { params(node: T.nilable(Object)).void }
    def visit(node)
      if node.is_a?(::Symbol)
        names << node.to_s
      elsif node.is_a?(::Parser::AST::Node)
        visit_all(node.children)
        names << "" if node.type == :cbase
      end
      # case node.type
      # when :const
      # names << node.location.name.source
      # when :cbase
      # names << "::"
      # end
    end
  end
end
