# typed: strict
# frozen_string_literal: true

module RBI
  class File
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
      p.visit_all(@root.body)
      out.string
    end
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
      previous = T.let(nil, T.nilable(Node))
      nodes.each_with_index do |node, _index|
        printn unless !previous || (previous.oneline?(self) && node.oneline?(self))
        visit(node)
        previous = node
      end
    end
  end

  module Node
    extend T::Sig

    sig { abstract.params(v: Printer).void }
    def accept_printer(v); end

    sig { abstract.params(_v: Printer).returns(T::Boolean) }
    def oneline?(_v); end
  end

  class Symbol
    extend T::Sig

    sig { override.params(_v: Printer).returns(T::Boolean) }
    def oneline?(_v)
      true
    end
  end

  class Scope
    extend T::Sig

    sig { override.params(v: Printer).void }
    def accept_printer(v)
      if oneline?(v)
        v.printn("; end")
        return
      end
      v.printn
      v.indent
      v.visit_all(body)
      v.dedent
      v.printl("end")
    end

    sig { override.params(v: Printer).returns(T::Boolean) }
    def oneline?(v)
      body.empty?
    end
  end

  class Call
    extend T::Sig

    sig { override.params(v: Printer).void }
    def accept_printer(v)
      v.printt(method.to_s)
      unless args.empty?
        v.print(" ")
        v.print(args.join(","))
      end
      v.printn
    end

    sig { override.params(_v: Printer).returns(T::Boolean) }
    def oneline?(_v)
      true
    end
  end

  class Module
    extend T::Sig

    sig { override.params(v: Printer).void }
    def accept_printer(v)
      v.printt("module #{name}")
      super(v)
    end

    sig { override.params(v: Printer).returns(T::Boolean) }
    def oneline?(v)
      !interface? && super(v)
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

    sig { override.params(v: Printer).returns(T::Boolean) }
    def oneline?(v)
      !abstract? && !sealed? && super(v)
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
        v.print(names.map { |name| ":#{name}" }.join(","))
      end
      v.printn
    end

    sig { override.params(_v: Printer).returns(T::Boolean) }
    def oneline?(_v)
      sigs.empty?
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

    sig { override.params(_v: Printer).returns(T::Boolean) }
    def oneline?(_v)
      sigs.empty?
    end
  end

  class Param
    extend T::Sig

    sig { override.params(v: Printer).void }
    def accept_printer(v)
      v.print(name.to_s)
      if is_keyword
        v.print(":")
      end
      value = self.value
      if value
        v.print(" =") unless is_keyword
        v.print(" #{value}")
      end
    end
  end

  # Sorbet

  class Sig
    extend T::Sig

    sig { override.params(v: Printer).void }
    def accept_printer(v)
      v.printt("sig { ")
      unless params.empty?
        v.print("params(")
        params.each_with_index do |param, index|
          v.print(", ") if index > 0
          v.print(param.name.to_s)
          v.print(": ")
          type = param.type
          if type
            v.print(type.to_s)
          else
            v.print("T.untyped")
          end
        end
        v.print(").")
      end
      returns = self.returns
      if returns == "void"
        v.print("void")
      elsif returns
        v.print("returns(#{returns})")
      else
        v.print("returns(T.untyped)")
      end
      v.printn(" }")
    end

    sig { override.params(_v: Printer).returns(T::Boolean) }
    def oneline?(_v)
      true
    end
  end
end
