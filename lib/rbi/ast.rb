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

  sig { params(nodes: T::Array[Stmt]).void }
  def concat(nodes)
    nodes.each { |node| self << node }
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
  end

  # Scopes

  class Scope < Stmt
    extend T::Sig
    extend T::Helpers

    abstract!

    sig { returns(String) }
    attr_accessor :name

    sig { returns(T::Array[Stmt]) }
    attr_reader :body

    sig { params(name: String, loc: T.nilable(Loc)).void }
    def initialize(name, loc: nil)
      super(loc: loc)
      @name = name
      @body = T.let([], T::Array[Stmt])
    end

    sig { params(node: Stmt).void }
    def <<(node)
      raise if node.parent_scope && !node.parent_scope&.body&.delete(node)
      node.parent_scope = self
      @body << node
    end

    sig { params(nodes: T::Array[Stmt]).void }
    def concat(nodes)
      nodes.each { |node| self << node }
    end

    sig { returns(String) }
    def qualified_name
      return name if name.start_with?("::")
      "#{parent_scope&.qualified_name}::#{name}"
    end

    sig { returns(String) }
    def to_s
      name
    end
  end

  class Module < Scope
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

  class Class < Scope
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

  class SClass < Scope
    extend T::Sig

    sig { params(loc: T.nilable(Loc)).void }
    def initialize(loc: nil)
      super("<self>", loc: loc)
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

  class CBase < Class
    extend T::Sig

    sig { void }
    def initialize
      super("<cbase>", superclass: nil)
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
      "#{parent_scope&.qualified_name}::#{name}"
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

    sig { returns(T::Boolean) }
    attr_reader :is_singleton

    sig { returns(T::Array[Param]) }
    attr_reader :params

    sig { returns(T.nilable(String)) }
    attr_reader :return_type

    sig { returns(T::Array[Sig]) }
    attr_reader :sigs

    sig do
      params(
        name: String,
        is_singleton: T::Boolean,
        params: T::Array[Param],
        return_type: T.nilable(String),
        loc: T.nilable(Loc),
      ).void
    end
    def initialize(name, is_singleton: false, params: [], return_type: nil, loc: nil)
      super(loc: loc)
      @name = name
      @is_singleton = is_singleton
      @params = params
      @return_type = return_type
      @sigs = T.let([], T::Array[Sig])
      @sigs << default_sig if params.one?(&:type) || return_type
    end

    sig { returns(Sig) }
    def default_sig
      Sig.new(params: params.empty? ? nil : params, returns: return_type)
    end

    sig { returns(String) }
    def qualified_name
      "#{parent_scope&.qualified_name}#{is_singleton ? '::' : '#'}#{name}"
    end

    sig { returns(String) }
    def to_s
      name
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

  class Arg < Param; end

  class OptArg < ParamWithValue; end

  class RestArg < Param; end

  class KwArg < Param; end

  class KwOptArg < ParamWithValue; end

  class KwRestArg < Param; end

  class BlockArg < Param; end

  # Sends

  class Send < Stmt
    extend T::Sig
    extend T::Helpers

    abstract!

    sig { returns(::Symbol) }
    attr_reader :method

    sig { returns(T::Array[String]) }
    attr_reader :args

    sig { params(method: ::Symbol, args: T::Array[String], loc: T.nilable(Loc)).void }
    def initialize(method, args = [], loc: nil)
      super(loc: loc)
      @method = method
      @args = args
    end

    sig { returns(String) }
    def qualified_name
      "#{parent_scope&.qualified_name}.#{method}(#{args.join(',')})"
    end

    sig { returns(String) }
    def to_s
      method.to_s
    end
  end

  # Attributes

  class Attr < Send
    extend T::Sig
    extend T::Helpers

    abstract!

    sig { returns(T::Array[Sig]) }
    attr_reader :sigs

    sig { params(kind: ::Symbol, names: T::Array[::Symbol], loc: T.nilable(Loc)).void }
    def initialize(kind, names, loc: nil)
      super(kind, names, loc: loc)
      @sigs = T.let([], T::Array[Sig])
    end

    sig { returns(T::Array[String]) }
    def names
      args
    end
  end

  class AttrReader < Attr
    extend T::Sig

    sig { params(name: ::Symbol, names: ::Symbol, type: T.nilable(String), loc: T.nilable(Loc)).void }
    def initialize(name, *names, type: nil, loc: nil)
      super(:attr_reader, [name, *names], loc: loc)
      @sigs << Sig.new(returns: type) if type
    end
  end

  class AttrWriter < Attr
    extend T::Sig

    sig { params(name: ::Symbol, names: ::Symbol, type: T.nilable(String), loc: T.nilable(Loc)).void }
    def initialize(name, *names, type: nil, loc: nil)
      super(:attr_writer, [name, *names], loc: loc)
      @sigs << Sig.new(params: [
        Param.new(T.must(self.names.first&.to_s), type: type),
      ], returns: "void") if type
    end
  end

  class AttrAccessor < Attr
    extend T::Sig

    sig { params(name: ::Symbol, names: ::Symbol, type: T.nilable(String), loc: T.nilable(Loc)).void }
    def initialize(name, *names, type: nil, loc: nil)
      super(:attr_accessor, [name, *names], loc: loc)
      @sigs << Sig.new(params: [
        Param.new(T.must(self.names.first&.to_s), type: type),
      ], returns: type) if type
    end
  end

  # Ancestors

  class Include < Send
    extend T::Sig

    sig { params(name: String, names: String, loc: T.nilable(Loc)).void }
    def initialize(name, *names, loc: nil)
      super(:include, [name, *names], loc: loc)
    end
  end

  class Extend < Send
    extend T::Sig

    sig { params(name: String, names: String, loc: T.nilable(Loc)).void }
    def initialize(name, *names, loc: nil)
      super(:extend, [name, *names], loc: loc)
    end
  end

  class Prepend < Send
    extend T::Sig

    sig { params(name: String, names: String, loc: T.nilable(Loc)).void }
    def initialize(name, *names, loc: nil)
      super(:prepend, [name, *names], loc: loc)
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
      super(:abstract!, [], loc: loc)
    end
  end

  class Interface < Send
    sig { params(loc: T.nilable(Loc)).void }
    def initialize(loc: nil)
      super(:interface!, [], loc: loc)
    end
  end

  class Sealed < Send
    sig { params(loc: T.nilable(Loc)).void }
    def initialize(loc: nil)
      super(:sealed!, [], loc: loc)
    end
  end

  class MixesInClassMethods < Send
    sig { params(name: String, names: String, loc: T.nilable(Loc)).void }
    def initialize(name, *names, loc: nil)
      super(:mixes_in_class_methods, [name, *names], loc: loc)
    end
  end

  class TypeMember < Send
    sig { params(name: String, names: String, loc: T.nilable(Loc)).void }
    def initialize(name, *names, loc: nil)
      super(:type_member, [name, *names], loc: loc)
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
      super(:prop, args, loc: loc)
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
      super(:const, args, loc: loc)
    end
  end

  # Sigs

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
      @body << Sig::Returns.new(returns) if returns
    end

    sig { params(node: Sig::Builder).void }
    def <<(node)
      @body << node
    end

    sig { returns(String) }
    def to_s
      "sig"
    end

    class Builder < Node
      extend T::Helpers

      abstract!
    end

    class Abstract < Builder; end
    class Override < Builder; end
    class Overridable < Builder; end

    class TypeParameters < Builder
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
        super(loc: loc)
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
        super(loc: loc)
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
        super(loc: loc)
        @type = type
      end
    end

    class Void < Builder; end
  end
end
