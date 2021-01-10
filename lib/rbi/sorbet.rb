# typed: strict
# frozen_string_literal: true

class RBI
  class Abstract < Call
    sig { void }
    def initialize
      super(:abstract!, [])
    end
  end

  class Interface < Call
    sig { void }
    def initialize
      super(:interface!, [])
    end
  end

  class Sealed < Call
    sig { void }
    def initialize
      super(:sealed!, [])
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

  # TODO remove
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
      args << type
      args << "default: #{default}" if default
      super(:prop, args)
    end
  end

  class TConst < Call
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

  class Sig < Node
    extend T::Sig
    include InScope

    sig { returns(T::Array[T.all(Node, InSig)]) }
    attr_reader :body

    sig { params(is_abstract: T::Boolean, params: T.nilable(T::Array[Param]), returns: T.nilable(String)).void }
    def initialize(is_abstract: false, params: nil, returns: nil)
      @body = T.let([], T::Array[T.all(Node, InSig)])
      @body << SAbstract.new if is_abstract
      @body << Params.new(params) if params
      @body << Returns.new(returns) if returns
    end

    sig { params(node: T.all(Node, InSig)).void }
    def <<(node)
      @body << node
    end
  end

  module InSig
    extend T::Helpers

    interface!
  end

  class SigModifier < Node
    extend T::Helpers
    include InSig

    abstract!
  end

  class SAbstract < SigModifier
    include InSig
  end

  class Returns < SigModifier
    extend T::Sig
    include InSig

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

  class Params < SigModifier
    extend T::Sig
    include InSig

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
end
