# typed: strict
# frozen_string_literal: true

class RBI
  extend T::Sig

  sig { returns(Module) }
  attr_reader :root

  sig { void }
  def initialize
    @root = T.let(Module.new("<root>"), Module)
  end

  sig { params(node: Def).void }
  def <<(node)
    @root << node
  end

  module Node
    extend T::Sig
    extend T::Helpers
    include Kernel

    interface!
  end

  # Something that can be defined at the top level of a RBI file
  class Symbol
    extend T::Sig
    extend T::Helpers
    include Node

    abstract!

    sig { returns(String) }
    attr_reader :name

    sig { params(name: String).void }
    def initialize(name)
      @name = name
    end

    sig { returns(String) }
    def to_s
      name.to_s
    end
  end

  module Def
    extend T::Helpers
    include Node

    interface!
  end

  class Scope < Symbol
    extend T::Sig
    extend T::Helpers
    include Def

    abstract!

    sig { returns(T::Array[Def]) }
    attr_reader :body

    sig { params(name: String).void }
    def initialize(name)
      super(name)
      @body = T.let([], T::Array[Def])
    end

    sig { params(node: Def).void }
    def <<(node)
      @body << node
    end
  end

  class Call
    extend T::Sig
    extend T::Helpers
    include Def

    abstract!

    sig { returns(::Symbol) }
    attr_reader :method

    sig { returns(T::Array[String]) }
    attr_reader :args

    sig { params(method: ::Symbol, args: T::Array[String]).void }
    def initialize(method, args = [])
      @method = method
      @args = args
    end
  end

  class Module < Scope
    extend T::Sig

    sig { params(name: String, interface: T::Boolean).void }
    def initialize(name, interface: false)
      super(name)
      interface! if interface
    end

    sig { void }
    def interface!
      body << Interface.new
    end

    sig { returns(T::Boolean) }
    def interface?
      body.one? { |body| body.is_a?(Interface) }
    end
  end

  class Interface < Call
    sig { void }
    def initialize
      super(:interface!, [])
    end
  end

  class Class < Scope
    extend T::Sig

    sig { returns(T.nilable(String)) }
    attr_reader :superclass

    sig do
      params(
        name: String,
        abstract: T::Boolean,
        sealed: T::Boolean,
        superclass: T.nilable(String)
      ).void
    end
    def initialize(name, abstract: false, sealed: false, superclass: nil)
      super(name)
      abstract! if abstract
      sealed! if sealed
      @superclass = superclass
    end

    sig { void }
    def abstract!
      body << Abstract.new
    end

    sig { returns(T::Boolean) }
    def abstract?
      body.one? { |body| body.is_a?(Abstract) }
    end

    sig { void }
    def sealed!
      body << Sealed.new
    end

    sig { returns(T::Boolean) }
    def sealed?
      body.one? { |body| body.is_a?(Sealed) }
    end
  end

  class Abstract < Call
    sig { void }
    def initialize
      super(:abstract!, [])
    end
  end

  class Sealed < Call
    sig { void }
    def initialize
      super(:sealed!, [])
    end
  end

  class TStruct < Class
    extend T::Sig

    sig do
      params(
        name: String,
        abstract: T::Boolean,
        sealed: T::Boolean,
      ).void
    end
    def initialize(name, abstract: false, sealed: false)
      super(name, abstract: abstract, sealed: sealed, superclass: "T::Struct")
    end
  end

  class TProp < Call
    extend T::Sig

    sig { params(name: String, type: String, default: T.nilable(String)).void }
    def initialize(name, type:, default: nil)
      args = []
      args << ":#{name}"
      args << "typed: #{type}"
      args << "default: #{default}" if default
      super(:prop, args)
    end
  end

  class Attr < Call
    extend T::Sig
    extend T::Helpers
    include Def

    abstract!

    sig { returns(T.nilable(String)) }
    attr_reader :type

    sig { returns(T::Array[Sig]) }
    attr_reader :sigs

    sig { params(kind: ::Symbol, names: T::Array[::Symbol], type: T.nilable(String)).void }
    def initialize(kind, names, type: nil)
      super(kind, names)
      @type = type
      @sigs = T.let([], T::Array[Sig])
      @sigs << default_sig if type
    end

    sig { abstract.returns(Sig) }
    def default_sig; end

    sig { returns(T::Array[String]) }
    def names
      args
    end
  end

  class AttrReader < Attr
    extend T::Sig

    sig { params(name: ::Symbol, names: ::Symbol, type: T.nilable(String)).void }
    def initialize(name, *names, type: nil)
      super(:attr_reader, [name, *names], type: type)
    end

    sig { override.returns(Sig) }
    def default_sig
      Sig.new(returns: type)
    end
  end

  class AttrWriter < Attr
    extend T::Sig

    sig { params(name: ::Symbol, names: ::Symbol, type: T.nilable(String)).void }
    def initialize(name, *names, type: nil)
      super(:attr_writer, [name, *names], type: type)
    end

    sig { override.returns(Sig) }
    def default_sig
      Sig.new(params: [
        Param.new(T.must(names.first&.to_s), type: type),
      ], returns: "void")
    end
  end

  class AttrAccessor < Attr
    extend T::Sig

    sig { params(name: ::Symbol, names: ::Symbol, type: T.nilable(String)).void }
    def initialize(name, *names, type: nil)
      super(:attr_accessor, [name, *names], type: type)
    end

    sig { override.returns(Sig) }
    def default_sig
      Sig.new(params: [
        Param.new(T.must(names.first), type: type),
      ], returns: type)
    end
  end

  class Const < Symbol
    extend T::Sig
    include Def

    sig { returns(T.nilable(String)) }
    attr_reader :value

    sig { params(name: String, value: T.nilable(String)).void }
    def initialize(name, value: nil)
      super(name)
      @value = value
    end
  end

  class Method < Symbol
    extend T::Sig
    include Def

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
        return_type: T.nilable(String)
      ).void
    end
    def initialize(name, is_singleton: false, params: [], return_type: nil)
      super(name)
      @is_singleton = is_singleton
      @params = params
      @return_type = return_type
      @sigs = T.let([], T::Array[Sig])
      @sigs << default_sig if !params.select(&:type).empty? || return_type
    end

    sig { returns(Sig) }
    def default_sig
      Sig.new(params: params, returns: return_type)
    end
  end

  class Param < Symbol
    extend T::Sig

    sig { returns(T::Boolean) }
    attr_reader :is_keyword

    sig { returns(T::Boolean) }
    attr_reader :is_rest

    sig { returns(T.nilable(String)) }
    attr_reader :value

    sig { returns(T.nilable(String)) }
    attr_reader :type

    sig do
      params(
        name: String,
        is_keyword: T::Boolean,
        is_rest: T::Boolean,
        value: T.nilable(String),
        type: T.nilable(String)
      ).void
    end
    def initialize(name, is_keyword: false, is_rest: false, value: nil, type: nil)
      super(name)
      @is_keyword = is_keyword
      @is_rest = is_rest
      @value = value
      @type = type
    end
  end

  class Include < Call
    extend T::Sig

    sig { params(name: String, names: String).void }
    def initialize(name, *names)
      super(:include, [name, *names])
    end
  end

  class Extend < Call
    extend T::Sig

    sig { params(name: String, names: String).void }
    def initialize(name, *names)
      super(:extend, [name, *names])
    end
  end

  class Prepend < Call
    extend T::Sig

    sig { params(name: String, names: String).void }
    def initialize(name, *names)
      super(:prepend, [name, *names])
    end
  end

  class MixesInClassMethods < Call
    sig { params(name: String, names: String).void }
    def initialize(name, *names)
      super(:mixes_in_class_methods, [name, *names])
    end
  end

  class TypeMember < Call
    sig { params(name: String, names: String).void }
    def initialize(name, *names)
      super(:type_member, [name, *names])
    end
  end

  class Visibility < Call
    extend T::Helpers

    abstract!
  end

  class Public < Visibility
  end

  class Private < Visibility
  end

  class Sig
    extend T::Sig
    include Def

    sig { returns(T::Array[Param]) }
    attr_reader :params

    sig { returns(T.nilable(String)) }
    attr_reader :returns

    sig { params(params: T::Array[Param], returns: T.nilable(String)).void }
    def initialize(params: [], returns: nil)
      @params = params
      @returns = returns
    end
  end
end
