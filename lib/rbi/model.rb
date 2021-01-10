# typed: strict
# frozen_string_literal: true

class RBI
  extend T::Sig

  sig { returns(Module) }
  attr_reader :root

  sig { params(block: T.nilable(T.proc.params(scope: RBI).void)).void }
  def initialize(&block)
    @root = T.let(Module.new("<root>"), Module)
    block&.call(self)
  end

  sig { params(node: T.all(Node, InScope)).void }
  def <<(node)
    @root << node
  end

  class Node
    extend T::Sig
    extend T::Helpers

    abstract!
  end

  # Scopes

  module InScope
    extend T::Helpers

    interface!
  end

  class Scope < Node
    extend T::Sig
    extend T::Helpers
    include InScope

    abstract!

    sig { returns(String) }
    attr_reader :name

    sig { returns(T::Array[T.all(Node, InScope)]) }
    attr_reader :body

    sig { params(name: String).void }
    def initialize(name)
      @name = name
      @body = T.let([], T::Array[T.all(Node, InScope)])
    end

    sig { params(node: T.all(Node, InScope)).void }
    def <<(node)
      @body << node
    end
  end

  class Module < Scope
    extend T::Sig

    sig { params(name: String, interface: T::Boolean, block: T.nilable(T.proc.params(scope: Module).void)).void }
    def initialize(name, interface: false, &block)
      super(name)
      interface! if interface
      block&.call(self)
    end

    sig { void }
    def interface!
      body << Interface.new
    end

    sig { returns(T::Boolean) }
    def interface?
      body.one? { |child| child.is_a?(Interface) }
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
        superclass: T.nilable(String),
        block: T.nilable(T.proc.params(scope: Class).void),
      ).void
    end
    def initialize(name, abstract: false, sealed: false, superclass: nil, &block)
      super(name)
      abstract! if abstract
      sealed! if sealed
      @superclass = superclass
      block&.call(self)
    end

    sig { void }
    def abstract!
      body << Abstract.new
    end

    sig { returns(T::Boolean) }
    def abstract?
      body.one? { |child| child.is_a?(Abstract) }
    end

    sig { void }
    def sealed!
      body << Sealed.new
    end

    sig { returns(T::Boolean) }
    def sealed?
      body.one? { |child| child.is_a?(Sealed) }
    end
  end

  # Consts

  class Const < Node
    extend T::Sig
    include InScope

    sig { returns(String) }
    attr_reader :name

    sig { returns(T.nilable(String)) }
    attr_reader :value

    sig { params(name: String, value: T.nilable(String)).void }
    def initialize(name, value: nil)
      @name = name
      @value = value
    end
  end

  # Defs

  class Method < Node
    extend T::Sig
    include InScope

    sig { returns(String) }
    attr_reader :name

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
        type: T.nilable(String)
      ).void
    end
    def initialize(name, type: nil)
      @name = name
      @type = type
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
        type: T.nilable(String)
      ).void
    end
    def initialize(name, value: nil, type: nil)
      super(name, type: type)
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

  # Calls

  class Call < Node
    extend T::Sig
    extend T::Helpers
    include InScope

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

  class Attr < Call
    extend T::Sig
    extend T::Helpers

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
        Param.new(T.must(names.first&.to_s), type: type),
      ], returns: type)
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

  class Visibility < Call
    extend T::Helpers

    abstract!
  end

  class Public < Visibility
    sig { void }
    def initialize
      super(:public)
    end
  end

  class Protected < Visibility
    sig { void }
    def initialize
      super(:protected)
    end
  end

  class Private < Visibility
    sig { void }
    def initialize
      super(:private)
    end
  end
end
