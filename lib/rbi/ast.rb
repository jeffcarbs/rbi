# typed: strict
# frozen_string_literal: true

class RBI
  extend T::Sig

  sig { returns(CBase) }
  attr_reader :root

  sig { void }
  def initialize
    @root = T.let(CBase.new, CBase)
  end

  sig { params(node: T.all(Node, Stmt)).void }
  def <<(node)
    @root << node
  end

  class Node
    extend T::Sig
    extend T::Helpers

    abstract!

    sig { returns(T.nilable(Loc)) }
    attr_accessor :loc

    sig { params(loc: T.nilable(Loc)).void }
    def initialize(loc: nil)
      @loc = loc
    end
  end

  class Comment < Node
    extend T::Helpers

    sig { returns(String) }
    attr_accessor :text

    sig { params(text: String, loc: T.nilable(Loc)).void }
    def initialize(text, loc: nil)
      super(loc: loc)
      @text = text
    end
  end

  class Stmt < Node
    extend T::Helpers

    abstract!

    sig { returns(T.nilable(Scope)) }
    attr_accessor :parent_scope

    sig { returns(T::Array[Comment]) }
    attr_accessor :comments

    sig { params(loc: T.nilable(Loc)).void }
    def initialize(loc: nil)
      super(loc: loc)
      @parent_scope = T.let(nil, T.nilable(Scope))
      @comments = T.let([], T::Array[Comment])
    end

    sig { returns(T.nilable(NamedScope)) }
    def named_parent_scope
      parent = T.let(parent_scope, T.nilable(Scope))
      while parent && !parent.is_a?(NamedScope)
        parent = parent.parent_scope
      end
      parent
    end
  end

  # Scopes

  class Scope < Stmt
    extend T::Sig
    extend T::Helpers

    abstract!

    sig { returns(T::Array[Stmt]) }
    attr_reader :body

    sig { params(loc: T.nilable(Loc)).void }
    def initialize(loc: nil)
      super(loc: loc)
      @body = T.let([], T::Array[Stmt])
    end

    sig { params(node: Stmt).void }
    def <<(node)
      node.parent_scope = self
      @body << node
    end
  end

  class NamedScope < Scope
    extend T::Helpers
    extend T::Sig

    abstract!

    sig { returns(String) }
    attr_accessor :name

    sig { params(name: String, loc: T.nilable(Loc)).void }
    def initialize(name, loc: nil)
      super(loc: loc)
      @name = name
    end

    sig { returns(String) }
    def qualified_name
      return name if name.start_with?("::")
      "#{named_parent_scope&.qualified_name}::#{name}"
    end

    sig { returns(String) }
    def to_s
      name
    end
  end

  class CBase < NamedScope
    extend T::Sig

    sig { void }
    def initialize
      super("<cbase>")
    end

    sig { returns(String) }
    def qualified_name
      ""
    end

    sig { returns(String) }
    def to_s
      "::"
    end
  end

  class Module < NamedScope
    extend T::Sig

    sig { params(name: String, loc: T.nilable(Loc)).void }
    def initialize(name, loc: nil)
      super(name, loc: loc)
    end

    sig { returns(T.self_type) }
    def interface!
      body << Interface.new
      self
    end

    sig { returns(T::Boolean) }
    def interface?
      body.one? { |child| child.is_a?(Interface) }
    end
  end

  class Class < NamedScope
    extend T::Sig

    sig { returns(T.nilable(String)) }
    attr_accessor :superclass

    sig do
      params(
        name: String,
        superclass: T.nilable(String),
        loc: T.nilable(Loc),
      ).void
    end
    def initialize(name, superclass: nil, loc: nil)
      super(name, loc: loc)
      @superclass = superclass
    end

    sig { returns(T.self_type) }
    def abstract!
      body << Abstract.new
      self
    end

    sig { returns(T::Boolean) }
    def abstract?
      body.one? { |child| child.is_a?(Abstract) }
    end

    sig { returns(T.self_type) }
    def sealed!
      body << Sealed.new
      self
    end

    sig { returns(T::Boolean) }
    def sealed?
      body.one? { |child| child.is_a?(Sealed) }
    end
  end

  class SClass < NamedScope
    extend T::Sig

    sig { params(loc: T.nilable(Loc)).void }
    def initialize(loc: nil)
      super("<self>", loc: loc)
    end
  end

  # Consts

  class Const < Stmt
    extend T::Sig

    sig { returns(String) }
    attr_accessor :name

    sig { returns(T.nilable(String)) }
    attr_accessor :value

    sig { params(name: String, value: T.nilable(String), loc: T.nilable(Loc)).void }
    def initialize(name, value: nil, loc: nil)
      super(loc: loc)
      @name = name
      @value = value
    end

    sig { returns(String) }
    def qualified_name
      return name if name.start_with?("::")
      "#{named_parent_scope&.qualified_name}::#{name}"
    end

    sig { returns(String) }
    def to_s
      name
    end
  end

  # Defs

  class Def < Stmt
    extend T::Sig

    sig { returns(String) }
    attr_accessor :name

    # TODO Params
    sig { returns(T::Array[Param]) }
    attr_reader :params

    sig { returns(T::Array[Sig]) }
    attr_reader :sigs

    sig do
      params(
        name: String,
        params: T::Array[Param],
        loc: T.nilable(Loc),
      ).void
    end
    def initialize(name, params: [], loc: nil)
      super(loc: loc)
      @name = name
      @params = params
      @sigs = T.let([], T::Array[Sig])
    end

    sig { returns(Sig) }
    def template_sig
      sig = Sig.new
      unless params.empty?
        sig << Sig::Params.new(
          params.map { |param| Param.new(param.name, type: "T.untyped") }
        )
      end
      sig << Sig::Returns.new("T.untyped")
      sig
    end

    sig { returns(String) }
    def qualified_name
      "#{named_parent_scope&.qualified_name}##{name}"
    end

    sig { returns(String) }
    def to_s
      name
    end
  end

  class DefS < Def
    extend T::Sig

    sig { returns(String) }
    def qualified_name
      "#{named_parent_scope&.qualified_name}::#{name}"
    end
  end

  # Params

  class Param < Node
    extend T::Helpers
    extend T::Sig

    abstract!

    sig { returns(String) }
    attr_reader :name

    sig { returns(T.nilable(String)) }
    attr_reader :type

    sig do
      params(
        name: String,
        type: T.nilable(String),
        loc: T.nilable(Loc)
      ).void
    end
    def initialize(name, type: nil, loc: nil)
      super(loc: loc)
      @name = name
      @type = type
    end

    sig { returns(String) }
    def to_s
      name
    end
  end

  class ParamWithValue < Param
    extend T::Helpers
    extend T::Sig

    abstract!

    sig { returns(T.nilable(String)) }
    attr_reader :value

    sig do
      params(
        name: String,
        value: T.nilable(String),
        type: T.nilable(String),
        loc: T.nilable(Loc)
      ).void
    end
    def initialize(name, value: nil, type: nil, loc: nil)
      super(name, type: type, loc: loc)
      @value = value
    end
  end

  # TODO remove? rename as param?

  class Arg < Param; end

  class OptArg < ParamWithValue; end

  class RestArg < Param; end

  class KwArg < Param; end

  class KwOptArg < ParamWithValue; end

  class KwRestArg < Param; end

  class BlockArg < Param; end

  # Sends

  # TODO Take arg or pairs
  class Send < Stmt
    extend T::Sig
    extend T::Helpers

    abstract!

    sig { returns(::Symbol) }
    attr_reader :method

    sig { returns(T::Array[String]) }
    attr_reader :args

    sig { params(method: ::Symbol, args: T::Array[String], loc: T.nilable(Loc)).void }
    def initialize(method, args: [], loc: nil)
      super(loc: loc)
      @method = method
      @args = args
    end

    sig { returns(String) }
    def qualified_name
      "#{named_parent_scope&.qualified_name}.#{method}(#{args.join(',')})"
    end

    sig { returns(String) }
    def to_s
      method.to_s
    end
  end

  # Attributes

  class Attr < Stmt
    extend T::Sig
    extend T::Helpers

    abstract!

    sig { returns(T::Array[Symbol]) }
    attr_reader :names

    sig { returns(T::Array[Sig]) }
    attr_reader :sigs

    sig { params(names: T::Array[::Symbol], loc: T.nilable(Loc)).void }
    def initialize(names, loc: nil)
      super(loc: loc)
      @names = names
      @sigs = T.let([], T::Array[Sig])
    end

    sig { returns(String) }
    def kind
      case self
      when AttrReader
        "attr_reader"
      when AttrWriter
        "attr_writer"
      when AttrAccessor
        "attr_accessor"
      else
        raise
      end
    end

    sig { returns(String) }
    def qualified_name
      "#{named_parent_scope&.qualified_name}.#{kind}(#{names.join(',')})"
    end

    sig { abstract.returns(Sig) }
    def template_sig; end
  end

  class AttrReader < Attr
    extend T::Sig

    sig { params(name: ::Symbol, names: ::Symbol, loc: T.nilable(Loc)).void }
    def initialize(name, *names, loc: nil)
      super([name, *names], loc: loc)
    end

    sig { override.returns(Sig) }
    def template_sig
      sig = Sig.new
      sig << Sig::Returns.new("T.untyped")
      sig
    end
  end

  class AttrWriter < Attr
    extend T::Sig

    sig { params(name: ::Symbol, names: ::Symbol, loc: T.nilable(Loc)).void }
    def initialize(name, *names, loc: nil)
      super([name, *names], loc: loc)
    end

    sig { override.returns(Sig) }
    def template_sig
      sig = Sig.new
      sig << Sig::Params.new(names.map { |name| Param.new(name.to_s, type: "T.untyped") })
      sig << Sig::Void.new
      sig
    end
  end

  class AttrAccessor < Attr
    extend T::Sig

    sig { params(name: ::Symbol, names: ::Symbol, loc: T.nilable(Loc)).void }
    def initialize(name, *names, loc: nil)
      super([name, *names], loc: loc)
    end

    sig { override.returns(Sig) }
    def template_sig
      sig = Sig.new
      sig << Sig::Params.new(names.map { |name| Param.new(name.to_s, type: "T.untyped") })
      sig << Sig::Returns.new("T.untyped")
      sig
    end
  end

  # Ancestors

  class Include < Send
    extend T::Sig

    sig { params(name: String, names: String, loc: T.nilable(Loc)).void }
    def initialize(name, *names, loc: nil)
      super(:include, args: [name, *names], loc: loc)
    end
  end

  class Extend < Send
    extend T::Sig

    sig { params(name: String, names: String, loc: T.nilable(Loc)).void }
    def initialize(name, *names, loc: nil)
      super(:extend, args: [name, *names], loc: loc)
    end
  end

  class Prepend < Send
    extend T::Sig

    sig { params(name: String, names: String, loc: T.nilable(Loc)).void }
    def initialize(name, *names, loc: nil)
      super(:prepend, args: [name, *names], loc: loc)
    end
  end

  # Visibility

  class Visibility < Send
    extend T::Helpers

    abstract!
  end

  class Public < Visibility
    sig { params(loc: T.nilable(Loc)).void }
    def initialize(loc: nil)
      super(:public, loc: loc)
    end
  end

  class Protected < Visibility
    sig { params(loc: T.nilable(Loc)).void }
    def initialize(loc: nil)
      super(:protected, loc: loc)
    end
  end

  class Private < Visibility
    sig { params(loc: T.nilable(Loc)).void }
    def initialize(loc: nil)
      super(:private, loc: loc)
    end
  end

  # Sorbet

  class Abstract < Send
    sig { params(loc: T.nilable(Loc)).void }
    def initialize(loc: nil)
      super(:abstract!, loc: loc)
    end
  end

  class Interface < Send
    sig { params(loc: T.nilable(Loc)).void }
    def initialize(loc: nil)
      super(:interface!, loc: loc)
    end
  end

  class Sealed < Send
    sig { params(loc: T.nilable(Loc)).void }
    def initialize(loc: nil)
      super(:sealed!, loc: loc)
    end
  end

  class MixesInClassMethods < Send
    sig { params(name: String, names: String, loc: T.nilable(Loc)).void }
    def initialize(name, *names, loc: nil)
      super(:mixes_in_class_methods, args: [name, *names], loc: loc)
    end
  end

  class TypeMember < Send
    sig { params(name: String, names: String, loc: T.nilable(Loc)).void }
    def initialize(name, *names, loc: nil)
      super(:type_member, args: [name, *names], loc: loc)
    end
  end

  class TProp < Send
    extend T::Sig

    sig { params(name: String, type: String, default: T.nilable(String), loc: T.nilable(Loc)).void }
    def initialize(name, type:, default: nil, loc: nil)
      args = []
      args << ":#{name}"
      args << type
      args << "default: #{default}" if default
      super(:prop, args: args, loc: loc)
    end
  end

  class TConst < Send
    extend T::Sig

    sig { params(name: String, type: String, default: T.nilable(String), loc: T.nilable(Loc)).void }
    def initialize(name, type:, default: nil, loc: nil)
      args = []
      args << ":#{name}"
      args << type
      args << "default: #{default}" if default
      super(:const, args: args, loc: loc)
    end
  end

  # Sigs

  # TODO simplify, not a block?
  class Sig < Stmt
    extend T::Sig

    sig { returns(T::Array[Sig::Builder]) }
    attr_reader :body

    sig do
      params(
        is_abstract: T::Boolean,
        params: T.nilable(T::Array[Param]),
        returns: T.nilable(String),
        loc: T.nilable(Loc)
      ).void
    end
    def initialize(is_abstract: false, params: nil, returns: nil, loc: nil)
      super(loc: loc)
      @body = T.let([], T::Array[Sig::Builder])
      @body << Sig::Abstract.new if is_abstract
      @body << Sig::Params.new(params) if params
      if returns
        @body << if returns == "void"
          Sig::Void.new
        else
          Sig::Returns.new(returns)
        end
      end
    end

    sig { params(node: Sig::Builder).void }
    def <<(node)
      @body << node
    end

    sig { returns(String) }
    def to_s
      "sig"
    end

    class Builder < Send
      extend T::Helpers

      abstract!
    end

    class Abstract < Builder
      sig { params(loc: T.nilable(Loc)).void }
      def initialize(loc: nil)
        super(:abstract, loc: loc)
      end
    end

    class Override < Builder
      sig { params(loc: T.nilable(Loc)).void }
      def initialize(loc: nil)
        super(:override, loc: loc)
      end
    end

    class Overridable < Builder
      sig { params(loc: T.nilable(Loc)).void }
      def initialize(loc: nil)
        super(:overridable, loc: loc)
      end
    end

    class Checked < Builder
      extend T::Sig

      sig { returns(T::Array[String]) }
      attr_reader :params

      sig do
        params(
          params: T::Array[String],
          loc: T.nilable(Loc)
        ).void
      end
      def initialize(params = [], loc: nil)
        super(:checked, args: params, loc: loc)
        @params = params
      end
    end

    class TypeParameters < Builder
      extend T::Sig

      sig { returns(T::Array[String]) }
      attr_reader :params

      sig do
        params(
          params: T::Array[String],
          loc: T.nilable(Loc)
        ).void
      end
      def initialize(params = [], loc: nil)
        super(:type_parameter, args: params, loc: loc)
        @params = params
      end
    end

    class Params < Builder
      extend T::Sig

      sig { returns(T::Array[Param]) }
      attr_reader :params

      sig do
        params(
          params: T::Array[Param],
          loc: T.nilable(Loc)
        ).void
      end
      def initialize(params = [], loc: nil)
        super(:params, loc: loc)
        @params = params
      end
    end

    class Returns < Builder
      extend T::Sig

      sig { returns(T.nilable(String)) }
      attr_reader :type

      sig do
        params(
          type: T.nilable(String),
          loc: T.nilable(Loc)
        ).void
      end
      def initialize(type = nil, loc: nil)
        super(:returns, loc: loc)
        @type = type
      end
    end

    class Void < Builder
      sig { params(loc: T.nilable(Loc)).void }
      def initialize(loc: nil)
        super(:void, loc: loc)
      end
    end
  end
end
