# typed: strict
# frozen_string_literal: true

class RBI
  extend T::Sig

  sig do
    params(
      out: T.any(IO, StringIO),
      default_indent: Integer,
      color: T::Boolean,
      show_locs: T::Boolean,
      show_comments: T::Boolean,
      fold_empty_scopes: T::Boolean,
      paren_attrs: T::Boolean,
      paren_includes: T::Boolean,
      paren_mixes: T::Boolean,
      paren_tprops: T::Boolean
    ).returns(String)
  end
  def to_rbi(
    out: $stdout,
    default_indent: 0,
    color: false,
    show_locs: false,
    show_comments: true,
    fold_empty_scopes: true,
    paren_attrs: false,
    paren_includes: false,
    paren_mixes: false,
    paren_tprops: false
  )
    out = StringIO.new
    p = Printer.new(
      out: out,
      default_indent: default_indent,
      color: color,
      show_locs: show_locs,
      show_comments: show_comments,
      fold_empty_scopes: fold_empty_scopes,
      paren_attrs: paren_attrs,
      paren_includes: paren_includes,
      paren_mixes: paren_mixes,
      paren_tprops: paren_tprops,
    )
    p.visit_body(root.body)
    out.string
  end

  class Printer < Visitor
    extend T::Sig

    sig { returns(T::Boolean) }
    attr_reader :color

    sig { returns(T::Boolean) }
    attr_reader :show_locs

    sig { returns(T::Boolean) }
    attr_reader :show_comments

    sig { returns(T::Boolean) }
    attr_reader :fold_empty_scopes

    sig { returns(T::Boolean) }
    attr_reader :paren_attrs

    sig { returns(T::Boolean) }
    attr_reader :paren_includes

    sig { returns(T::Boolean) }
    attr_reader :paren_mixes

    sig { returns(T::Boolean) }
    attr_reader :paren_tprops

    sig do
      params(
        out: T.any(IO, StringIO),
        default_indent: Integer,
        color: T::Boolean,
        show_locs: T::Boolean,
        show_comments: T::Boolean,
        fold_empty_scopes: T::Boolean,
        paren_attrs: T::Boolean,
        paren_includes: T::Boolean,
        paren_mixes: T::Boolean,
        paren_tprops: T::Boolean
      ).void
    end
    def initialize(
      out: $stdout,
      default_indent: 0,
      color: false,
      show_locs: false,
      show_comments: true,
      fold_empty_scopes: true,
      paren_attrs: false,
      paren_includes: false,
      paren_mixes: false,
      paren_tprops: false
    )
      super()
      @out = out
      @current_indent = default_indent
      @color = color
      @show_locs = show_locs
      @show_comments = show_comments
      @fold_empty_scopes = fold_empty_scopes
      @paren_attrs = paren_attrs
      @paren_includes = paren_includes
      @paren_mixes = paren_mixes
      @paren_tprops = paren_tprops
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

    sig { params(string: String, color: Symbol).returns(String) }
    def colorize(string, color)
      return string unless @color
      string.colorize(color)
    end

    sig { override.params(node: T.nilable(Node)).void }
    def visit(node)
      return unless node
      node.accept_printer(self)
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
      # return true if node.is_a?(Visibility) || last.is_a?(Visibility)
      # return true if node.is_a?(Def) && !last.is_a?(Sig) && (!node.is_a?(last.class) && !last.is_a?(node.class))
      # return true if last.is_a?(Def) && last.name == "initialize"
      # return true if node.is_a?(Def) && last.is_a?(Def) && last.is_singleton != node.is_singleton
      return true if node.is_a?(Attr) && !node.sigs.empty?
      return true if node.is_a?(Def) && !node.sigs.empty?
      return true if node.is_a?(Sig) && !last.is_a?(Sig)
      # return true if !node.is_a?(Sig) && last
      return true if !last.is_a?(Sig) && (
        (before_last&.is_a?(Def) && !before_last.sigs.empty?) ||
        (before_last&.is_a?(Attr) && !before_last.sigs.empty?) ||
        before_last&.is_a?(Sig)
      )
      false
    end
  end

  class Node
    extend T::Sig

    sig { abstract.params(v: Printer).void }
    def accept_printer(v); end
  end

  class Comment
    extend T::Sig

    sig { override.params(v: Printer).void }
    def accept_printer(v)
      v.printl(v.colorize(text, :light_black))
    end
  end

  class Scope
    extend T::Sig

    sig { override.params(v: Printer).void }
    def accept_printer(v)
      if body.empty?
        if v.fold_empty_scopes
          v.printn("; end")
        else
          v.printn
          v.printl(v.colorize("end", :blue))
        end
        return
      end
      v.printn
      v.indent
      v.visit_body(body)
      v.dedent
      v.printl(v.colorize("end", :blue))
    end
  end

  class Module
    extend T::Sig

    sig { override.params(v: Printer).void }
    def accept_printer(v)
      v.visit_all(comments)
      v.printl("# #{loc}") if loc && v.show_locs
      v.printt("#{v.colorize('module', :blue)} #{v.colorize(name, :cyan)}")
      super(v)
    end
  end

  class Class
    extend T::Sig

    sig { override.params(v: Printer).void }
    def accept_printer(v)
      v.visit_all(comments)
      v.printl("# #{loc}") if loc && v.show_locs
      v.printt("#{v.colorize('class', :blue)} #{v.colorize(name, :cyan)}")
      v.print(" < #{superclass}") if superclass
      super(v)
    end
  end

  class SClass
    extend T::Sig

    sig { override.params(v: Printer).void }
    def accept_printer(v)
      v.visit_all(comments)
      v.printl("# #{loc}") if loc && v.show_locs
      v.printt("#{v.colorize('class', :blue)} << #{v.colorize('self', :magenta)}")
      super(v)
    end
  end

  class Const
    extend T::Sig

    sig { override.params(v: Printer).void }
    def accept_printer(v)
      v.visit_all(comments)
      v.printt(v.colorize(name, :cyan))
      value = self.value
      if value
        v.print(" = #{value}")
      end
      v.print(" # #{loc}") if loc && v.show_locs
      v.printn
    end
  end

  class Def
    extend T::Sig

    sig { override.params(v: Printer).void }
    def accept_printer(v)
      v.visit_all(comments)
      sigs.each { |sig| v.visit(sig) }
      v.printt("#{v.colorize('def', :blue)} ")
      v.print("#{v.colorize('self', :magenta)}.") if is_singleton
      v.print(v.colorize(name.to_s, :light_green))
      unless params.empty?
        v.print("(")
        params.each_with_index do |param, index|
          v.print(", ") if index > 0
          v.visit(param)
        end
        v.print(")")
      end
      v.print("; #{v.colorize('end', :cyan)}")
      v.print(" # #{loc}") if loc && v.show_locs
      v.printn
    end
  end

  class Send
    extend T::Sig

    sig { override.params(v: Printer).void }
    def accept_printer(v)
      v.visit_all(comments)
      v.printt(v.colorize(method.to_s, :yellow))
      unless args.empty?
        parens = case self
        when Include, Extend, Prepend
          v.paren_includes
        when MixesInClassMethods
          v.paren_mixes
        when TProp, TConst
          v.paren_tprops
        else
          false
        end
        v.print(parens ? "(" : " ")
        v.print(args.map { |arg| v.colorize(arg, :cyan) }.join(", "))
        v.print(parens ? ")" : "")
      end
      v.print(" # #{loc}") if loc && v.show_locs
      v.printn
    end
  end

  class Attr
    extend T::Sig

    sig { override.params(v: Printer).void }
    def accept_printer(v)
      v.visit_all(comments)
      sigs.each { |sig| v.visit(sig) }
      v.printt(v.colorize(method.to_s, :yellow))
      unless names.empty?
        v.print(v.paren_attrs ? "(" : " ")
        v.print(names.map { |name| ":#{v.colorize(name.to_s, :light_magenta)}" }.join(", "))
        v.print(v.paren_attrs ? ")" : "")
      end
      v.print(" # #{loc}") if loc && v.show_locs
      v.printn
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

    sig { override.params(v: Printer).void }
    def accept_printer(v)
      v.visit_all(comments)
      v.printl("# #{loc}") if loc && v.show_locs
      v.printt(v.colorize("sig {", :light_black))
      unless body.empty?
        v.print(" ")
        body.each_with_index do |builder, index|
          v.print(".") if index > 0
          v.visit(builder)
        end
        v.print(" ")
      end
      v.printn(v.colorize("}", :light_black))
    end

    class Abstract
      extend T::Sig

      sig { override.params(v: Printer).void }
      def accept_printer(v)
        v.print(v.colorize("abstract", :light_black))
      end
    end

    class Override
      extend T::Sig

      sig { override.params(v: Printer).void }
      def accept_printer(v)
        v.print(v.colorize("override", :light_black))
      end
    end

    class Overridable
      extend T::Sig

      sig { override.params(v: Printer).void }
      def accept_printer(v)
        v.print(v.colorize("overridable", :light_black))
      end
    end

    class Params
      extend T::Sig

      sig { override.params(v: Printer).void }
      def accept_printer(v)
        v.print(v.colorize('params(', :light_black))
        params.each_with_index do |param, index|
          v.print(v.colorize(', ', :light_black)) if index > 0
          v.print(v.colorize("#{param.name}: #{param.type}", :light_black))
        end
        v.print(v.colorize(')', :light_black))
      end
    end

    class Returns
      extend T::Sig

      sig { override.params(v: Printer).void }
      def accept_printer(v)
        v.print(v.colorize("returns(#{type})", :light_black))
      end
    end

    class TypeParameters
      extend T::Sig

      sig { override.params(v: Printer).void }
      def accept_printer(v)
        v.print(v.colorize("type_parameters", :light_black))
      end
    end

    class Void
      extend T::Sig

      sig { override.params(v: Printer).void }
      def accept_printer(v)
        v.print(v.colorize("void", :light_black))
      end
    end
  end
end
