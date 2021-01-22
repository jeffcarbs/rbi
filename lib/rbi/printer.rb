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
      max_len: T.nilable(Integer),
      fold_sigs: T::Boolean,
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
    max_len: nil,
    fold_sigs: true,
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
      max_len: max_len,
      fold_sigs: fold_sigs,
      fold_empty_scopes: fold_empty_scopes,
      paren_attrs: paren_attrs,
      paren_includes: paren_includes,
      paren_mixes: paren_mixes,
      paren_tprops: paren_tprops,
    )
    p.visit_scope(root.body)
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

    sig { returns(T.nilable(Integer)) }
    attr_reader :max_len

    sig { returns(T::Boolean) }
    attr_reader :fold_sigs

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
        max_len: T.nilable(Integer),
        fold_sigs: T::Boolean,
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
      max_len: nil,
      fold_sigs: true,
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
      @max_len = max_len
      @fold_sigs = fold_sigs
      @fold_empty_scopes = fold_empty_scopes
      @paren_attrs = paren_attrs
      @paren_includes = paren_includes
      @paren_mixes = paren_mixes
      @paren_tprops = paren_tprops
      @fold_sig = T.let(false, T::Boolean)
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
    def visit_scope(nodes)
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

    sig { returns(T::Boolean) }
    attr_accessor :fold_sig
  end

  class Node
    extend T::Sig

    sig { abstract.params(v: Printer).void }
    def accept_printer(v); end

    # TODO to rbi
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
      v.visit_all(comments)
      v.printl("# #{loc}") if loc && v.show_locs
      case self
      when Module
        v.printt("#{v.colorize('module', :blue)} #{v.colorize(name, :cyan)}")
      when Class
        v.printt("#{v.colorize('class', :blue)} #{v.colorize(name, :cyan)}")
        v.print(" < #{v.colorize(T.must(superclass), :cyan)}") if superclass
      when SClass
        v.printt("#{v.colorize('class', :blue)} << #{v.colorize('self', :magenta)}")
      end
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
      v.visit_scope(body)
      v.dedent
      v.printl(v.colorize("end", :blue))
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
      v.print("#{v.colorize('self', :magenta)}.") if self.is_a?(DefS)
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
      name = case self
      when AttrReader
        "attr_reader"
      when AttrWriter
        "attr_writer"
      when AttrAccessor
        "attr_accessor"
      else
        raise
      end
      v.printt(v.colorize(name, :yellow))
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
      if v.fold_sigs
        max_len = v.max_len
        if max_len
          try = StringIO.new
          tv = Printer.new(fold_sigs: true, max_len: nil, out: try)
          tv.visit(self)
          v.fold_sig = try.string.size < max_len
        else
          v.fold_sig = true
        end
      end
      v.printl("# #{loc}") if loc && v.show_locs
      if v.fold_sig
        v.printt(v.colorize("sig {", :light_black))
      else
        v.printl(v.colorize("sig do", :light_black))
        v.indent
      end
      was_indented = T.let(false, T::Boolean)
      unless body.empty?
        v.print(" ") if v.fold_sig
        body.each_with_index do |builder, index|
          v.printt unless v.fold_sig
          v.print(".") if index > 0
          v.visit(builder)
          v.printn unless v.fold_sig
          if !v.fold_sig && builder.is_a?(TypeParameters)
            was_indented = true
            v.indent
          end
        end
        v.print(" ") if v.fold_sig
      end
      if v.fold_sig
        v.printn(v.colorize("}", :light_black))
      else
        v.dedent if was_indented
        v.dedent
        v.printl(v.colorize("end", :light_black))
      end
      v.fold_sig = false
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
        v.print(v.colorize('params', :light_black))
        unless params.empty?
          v.print(v.colorize('(', :light_black))
          v.printn unless v.fold_sig
          v.indent
          params.each_with_index do |param, index|
            if index > 0
              v.print(v.colorize(',', :light_black))
              v.print(" ") if v.fold_sig
              v.printn unless v.fold_sig
            end
            v.printt unless v.fold_sig
            v.print(v.colorize("#{param.name}: #{param.type}", :light_black))
          end
          v.dedent
          unless v.fold_sig
            v.printn
            v.printt
          end
          v.print(v.colorize(')', :light_black))
        end
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
        unless params.empty?
          v.print(v.colorize('(', :light_black))
          params.each_with_index do |param, index|
            v.print(v.colorize(', ', :light_black)) if index > 0
            v.print(v.colorize(":#{param}", :light_black))
          end
          v.print(v.colorize(')', :light_black))
        end
      end
    end

    class Checked
      extend T::Sig

      sig { override.params(v: Printer).void }
      def accept_printer(v)
        v.print(v.colorize("checked", :light_black))
        unless params.empty?
          v.print(v.colorize('(', :light_black))
          params.each_with_index do |param, index|
            v.print(v.colorize(', ', :light_black)) if index > 0
            v.print(v.colorize(":#{param}", :light_black))
          end
          v.print(v.colorize(')', :light_black))
        end
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
