# typed: strict
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

    sig { params(node: T.nilable(AST::Node)).void }
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
end
