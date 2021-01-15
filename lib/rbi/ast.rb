# typed: strict
# frozen_string_literal: true

class RBI
  extend T::Sig

  sig { returns(CBase) }
  attr_reader :root

  sig { params(block: T.nilable(T.proc.params(scope: RBI).void)).void }
  def initialize(&block)
    @root = T.let(CBase.new, CBase)
    block&.call(self)
  end

  sig { params(node: T.all(Node, Stmt)).void }
  def <<(node)
    @root << node
  end

  class Node
    extend T::Sig
    extend T::Helpers

    abstract!
  end

  # class Begin < Node
  # extend T::Sig
  # extend Enumerable
  #
  # sig { returns(T::Array[Node]) }
  # attr_reader :stmts
  #
  # sig { void }
  # def initialize
  # super()
  # @stmts = T.let([], T::Array[Node])
  # end
  #
  # sig { params(node: Node).void }
  # def <<(node)
  # @stmts << node
  # end
  #
  # sig { params(block: T.proc.params(node: Node).returns(Node)).returns(T::Enumerable[Node]) }
  # def each(&block)
  # stmts.each { |stmt| block.call(stmt) }
  # end
  # end

  # Scopes

  class Stmt < Node
    extend T::Helpers

    abstract!

    sig { returns(T.nilable(Scope)) }
    attr_accessor :parent_scope

    sig { void }
    def initialize
      @parent_scope = T.let(nil, T.nilable(Scope))
    end
  end

  class Scope < Stmt
    extend T::Sig
    extend T::Helpers

    abstract!

    sig { returns(String) }
    attr_accessor :name

    sig { returns(T::Array[T.all(Node, Stmt)]) }
    attr_reader :body

    sig { params(name: String).void }
    def initialize(name)
      super()
      @name = name
      @body = T.let([], T::Array[T.all(Node, Stmt)])
    end

    sig { returns(T::Boolean) }
    def root?
      false
    end

    sig { params(node: Stmt).void }
    def <<(node)
      node.parent_scope = self
      @body << node
    end

    sig { returns(String) }
    def qualified_name
      return name if name.start_with?("::")
      "#{parent_scope&.qualified_name}::#{name}"
    end
  end

  class Module < Scope
    extend T::Sig

    sig { params(name: String, block: T.nilable(T.proc.params(scope: Module).void)).void }
    def initialize(name, &block)
      super(name)
      block&.call(self)
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
        block: T.nilable(T.proc.params(scope: Class).void),
      ).void
    end
    def initialize(name, superclass: nil, &block)
      super(name)
      @superclass = superclass
      block&.call(self)
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

    sig { returns(T::Boolean) }
    def root?
      true
    end

    sig { returns(String) }
    def qualified_name
      ""
    end
  end

  # Consts

  class Const < Stmt
    extend T::Sig

    sig { returns(String) }
    attr_accessor :name

    sig { returns(T.nilable(String)) }
    attr_accessor :value

    sig { params(name: String, value: T.nilable(String)).void }
    def initialize(name, value: nil)
      super()
      @name = name
      @value = value
    end

    sig { returns(String) }
    def qualified_name
      return name if name.start_with?("::")
      "#{parent_scope&.qualified_name}::#{name}"
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
        return_type: T.nilable(String)
      ).void
    end
    def initialize(name, is_singleton: false, params: [], return_type: nil)
      super()
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
      super()
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

  # Sends

  class Send < Stmt
    extend T::Sig
    extend T::Helpers

    abstract!

    sig { returns(::Symbol) }
    attr_reader :method

    sig { returns(T::Array[String]) }
    attr_reader :args

    sig { params(method: ::Symbol, args: T::Array[String]).void }
    def initialize(method, args = [])
      super()
      @method = method
      @args = args
    end

    sig { returns(String) }
    def qualified_name
      "#{parent_scope&.qualified_name}.#{method}(#{args.join(',')})"
    end
  end

  # Attributes

  class Attr < Send
    extend T::Sig
    extend T::Helpers

    abstract!

    sig { returns(T::Array[Sig]) }
    attr_reader :sigs

    sig { params(kind: ::Symbol, names: T::Array[::Symbol]).void }
    def initialize(kind, names)
      super(kind, names)
      @sigs = T.let([], T::Array[Sig])
    end

    sig { returns(T::Array[String]) }
    def names
      args
    end
  end

  class AttrReader < Attr
    extend T::Sig

    sig { params(name: ::Symbol, names: ::Symbol, type: T.nilable(String)).void }
    def initialize(name, *names, type: nil)
      super(:attr_reader, [name, *names])
      @sigs << Sig.new(returns: type) if type
    end
  end

  class AttrWriter < Attr
    extend T::Sig

    sig { params(name: ::Symbol, names: ::Symbol, type: T.nilable(String)).void }
    def initialize(name, *names, type: nil)
      super(:attr_writer, [name, *names])
      @sigs << Sig.new(params: [
        Param.new(T.must(self.names.first&.to_s), type: type),
      ], returns: "void") if type
    end
  end

  class AttrAccessor < Attr
    extend T::Sig

    sig { params(name: ::Symbol, names: ::Symbol, type: T.nilable(String)).void }
    def initialize(name, *names, type: nil)
      super(:attr_accessor, [name, *names])
      @sigs << Sig.new(params: [
        Param.new(T.must(self.names.first&.to_s), type: type),
      ], returns: type) if type
    end
  end

  # Ancestors

  class Include < Send
    extend T::Sig

    sig { params(name: String, names: String).void }
    def initialize(name, *names)
      super(:include, [name, *names])
    end
  end

  class Extend < Send
    extend T::Sig

    sig { params(name: String, names: String).void }
    def initialize(name, *names)
      super(:extend, [name, *names])
    end
  end

  class Prepend < Send
    extend T::Sig

    sig { params(name: String, names: String).void }
    def initialize(name, *names)
      super(:prepend, [name, *names])
    end
  end

  # Visibility

  class Visibility < Send
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

  # Sorbet

  class Abstract < Send
    sig { void }
    def initialize
      super(:abstract!, [])
    end
  end

  class Interface < Send
    sig { void }
    def initialize
      super(:interface!, [])
    end
  end

  class Sealed < Send
    sig { void }
    def initialize
      super(:sealed!, [])
    end
  end

  class MixesInClassDefs < Send
    sig { params(name: String, names: String).void }
    def initialize(name, *names)
      super(:mixes_in_class_methods, [name, *names])
    end
  end

  class TypeMember < Send
    sig { params(name: String, names: String).void }
    def initialize(name, *names)
      super(:type_member, [name, *names])
    end
  end

  class TProp < Send
    extend T::Sig

    sig { params(name: String, type: String, default: T.nilable(String)).void }
    def initialize(name, type:, default: nil)
      args = []
      args << ":#{name}"
      args << type
      args << "default: #{default}" if default
      super(:prop, args)
    end
  end

  class TConst < Send
    extend T::Sig

    sig { params(name: String, type: String, default: T.nilable(String)).void }
    def initialize(name, type:, default: nil)
      args = []
      args << ":#{name}"
      args << type
      args << "default: #{default}" if default
      super(:const, args)
    end
  end

  # Sigs

  class Sig < Stmt
    extend T::Sig

    sig { returns(T::Array[SigBuilder]) }
    attr_reader :body

    sig { params(is_abstract: T::Boolean, params: T.nilable(T::Array[Param]), returns: T.nilable(String)).void }
    def initialize(is_abstract: false, params: nil, returns: nil)
      super()
      @body = T.let([], T::Array[SigBuilder])
      @body << SAbstract.new if is_abstract
      @body << Params.new(params) if params
      @body << Returns.new(returns) if returns
    end

    sig { params(node: SigBuilder).void }
    def <<(node)
      @body << node
    end
  end

  class SigBuilder < Node
    extend T::Helpers

    abstract!
  end

  class Returns < SigBuilder
    extend T::Sig

    sig { returns(T.nilable(String)) }
    attr_reader :type

    sig do
      params(
        type: T.nilable(String)
      ).void
    end
    def initialize(type = nil)
      super()
      @type = type
    end
  end

  class Params < SigBuilder
    extend T::Sig

    sig { returns(T::Array[Param]) }
    attr_reader :params

    sig do
      params(
        params: T::Array[Param],
      ).void
    end
    def initialize(params = [])
      super()
      @params = params
    end
  end

  class SAbstract < SigBuilder
    extend T::Sig
  end
end
