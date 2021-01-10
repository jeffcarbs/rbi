# typed: strict
# frozen_string_literal: true

class RBI
  extend T::Sig

  sig do
    params(
      out: T.any(IO, StringIO),
      default_indent: Integer,
    ).returns(String)
  end
  def to_rbi(
    out: $stdout,
    default_indent: 0
  )
    out = StringIO.new
    p = Printer.new(
      out: out,
      default_indent: default_indent,
    )
    p.visit_body(root.body)
    out.string
  end

  class Printer
    extend T::Sig

    sig do
      params(
        out: T.any(IO, StringIO),
        default_indent: Integer,
      ).void
    end
    def initialize(
      out: $stdout,
      default_indent: 0
    )
      @current_indent = default_indent
      @out = out
    end

    # Printing

    sig { void }
    def indent
      @current_indent += 2
    end

    sig { void }
    def dedent
      @current_indent -= 2
    end

    sig { params(string: String).void }
    def print(string)
      @out.print(string)
    end

    sig { params(string: T.nilable(String)).void }
    def printn(string = nil)
      print(string) if string
      print("\n")
    end

    sig { params(string: T.nilable(String)).void }
    def printt(string = nil)
      print(" " * @current_indent)
      print(string) if string
    end

    sig { params(string: String).void }
    def printl(string)
      printt
      printn(string)
    end

    sig { params(node: T.nilable(Node)).void }
    def visit(node)
      return unless node
      node.accept_printer(self)
    end

    sig { params(nodes: T::Array[Node]).void }
    def visit_all(nodes)
      nodes.each { |node| visit(node) }
    end

    sig { params(nodes: T::Array[Node]).void }
    def visit_body(nodes)
      previous = T::Array[Node].new
      nodes.each_with_index do |node, _index|
        printn if blank_before?(node, previous)
        visit(node)
        previous << node
      end
    end

    sig { params(node: Node).returns(T::Boolean) }
    def oneline?(node)
      return false if node.is_a?(Scope) && !node.body.empty?
      true
    end

    sig { params(node: Node, previous: T::Array[Node]).returns(T::Boolean) }
    def blank_before?(node, previous)
      last = previous[-1]
      before_last = previous[-2]
      return false unless last
      return true unless oneline?(node)
      return true unless oneline?(last) && oneline?(node)
      return true if node.is_a?(Attr) && !node.sigs.empty?
      return true if node.is_a?(Method) && !node.sigs.empty?
      return true if node.is_a?(Sig) && !last.is_a?(Sig)
      # return true if !node.is_a?(Sig) && last
      return true if !last.is_a?(Sig) && (
        (before_last&.is_a?(Method) && !before_last.sigs.empty?) ||
        (before_last&.is_a?(Attr) && !before_last.sigs.empty?) ||
        before_last&.is_a?(Sig)
      )
      false
    end
  end

  module Printable
    extend T::Sig

    sig do
      params(
        out: T.any(IO, StringIO),
        default_indent: Integer,
      ).returns(String)
    end
    def to_rbi(
      out: $stdout,
      default_indent: 0
    )
      out = StringIO.new
      p = Printer.new(
        out: out,
        default_indent: default_indent,
      )
      p.visit(T.cast(self, Node))
      out.string
    end
  end

  class Node
    extend T::Sig
    include Printable

    sig { abstract.params(v: Printer).void }
    def accept_printer(v); end
  end

  class Scope
    extend T::Sig

    sig { override.params(v: Printer).void }
    def accept_printer(v)
      if body.empty?
        v.printn("; end")
        return
      end
      v.printn
      v.indent
      v.visit_body(body)
      v.dedent
      v.printl("end")
    end
  end

  class Send
    extend T::Sig

    sig { override.params(v: Printer).void }
    def accept_printer(v)
      v.printt(method.to_s)
      unless args.empty?
        v.print(" ")
        v.print(args.join(", "))
      end
      v.printn
    end
  end

  class Module
    extend T::Sig

    sig { override.params(v: Printer).void }
    def accept_printer(v)
      v.printt("module #{name}")
      super(v)
    end
  end

  class Class
    extend T::Sig

    sig { override.params(v: Printer).void }
    def accept_printer(v)
      v.printt("class #{name}")
      if superclass
        v.print(" < #{superclass}")
      end
      super(v)
    end
  end

  class Attr
    extend T::Sig

    sig { override.params(v: Printer).void }
    def accept_printer(v)
      sigs.each { |sig| v.visit(sig) }
      v.printt(method.to_s)
      unless names.empty?
        v.print(" ")
        v.print(names.map { |name| ":#{name}" }.join(", "))
      end
      v.printn
    end
  end

  class Const
    extend T::Sig

    sig { override.params(v: Printer).void }
    def accept_printer(v)
      v.printt(name.to_s)
      value = self.value
      if value
        v.print(" = #{value}")
      end
      v.printn
    end
  end

  class Method
    extend T::Sig

    sig { override.params(v: Printer).void }
    def accept_printer(v)
      sigs.each { |sig| v.visit(sig) }
      v.printt("def ")
      v.print("self.") if is_singleton
      v.print(name.to_s)
      unless params.empty?
        v.print("(")
        params.each_with_index do |param, index|
          v.print(", ") if index > 0
          v.visit(param)
        end
        v.print(")")
      end
      v.printn("; end")
    end
  end

  class Arg
    extend T::Sig

    sig { override.params(v: Printer).void }
    def accept_printer(v)
      v.print(name.to_s)
    end
  end

  class OptArg
    extend T::Sig

    sig { override.params(v: Printer).void }
    def accept_printer(v)
      v.print("#{name} = #{value}")
    end
  end

  class RestArg
    extend T::Sig

    sig { override.params(v: Printer).void }
    def accept_printer(v)
      v.print("*#{name}")
    end
  end

  class KwArg
    extend T::Sig

    sig { override.params(v: Printer).void }
    def accept_printer(v)
      v.print("#{name}:")
    end
  end

  class KwOptArg
    extend T::Sig

    sig { override.params(v: Printer).void }
    def accept_printer(v)
      v.print("#{name}: #{value}")
    end
  end

  class KwRestArg
    extend T::Sig

    sig { override.params(v: Printer).void }
    def accept_printer(v)
      v.print("**#{name}")
    end
  end

  class BlockArg
    extend T::Sig

    sig { override.params(v: Printer).void }
    def accept_printer(v)
      v.print("&#{name}")
    end
  end

  # Sorbet

  class Sig
    extend T::Sig
    include Printable

    sig { override.params(v: Printer).void }
    def accept_printer(v)
      v.printt("sig {")
      unless body.empty?
        v.print(" ")
        body.each_with_index do |builder, index|
          v.print(".") if index > 0
          v.visit(builder)
        end
        v.print(" ")
      end
      v.printn("}")
    end
  end

  class SAbstract
    extend T::Sig
    include InSig

    sig { override.params(v: Printer).void }
    def accept_printer(v)
      v.print("abstract")
    end
  end

  class Returns
    extend T::Sig
    include InSig

    sig { override.params(v: Printer).void }
    def accept_printer(v)
      v.print(type == "void" ? "void" : "returns(#{type})")
    end
  end

  class Params
    extend T::Sig
    include InSig

    sig { override.params(v: Printer).void }
    def accept_printer(v)
      v.print("params(")
      params.each_with_index do |param, index|
        v.print(", ") if index > 0
        v.print("#{param.name}: #{param.type}")
      end
      v.print(")")
    end
  end
end
