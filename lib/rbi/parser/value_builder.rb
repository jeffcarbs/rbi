# typed: strict
# frozen_string_literal: true

class RBI
  class ExpBuilder
    extend T::Sig

    sig { params(string: String).returns(T.nilable(String)) }
    def self.parse(string)
      node = Parser.parse_string(string)
      return nil unless node
      build(node)
    end

    sig { params(node: AST::Node).returns(T.nilable(String)) }
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
      @out = T.let(StringIO.new, StringIO)
    end

    sig { params(node: T.nilable(AST::Node)).void }
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
        @out << "\"#{node.children[0].to_s}\""
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
end
