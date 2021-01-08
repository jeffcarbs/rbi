# typed: strict
# frozen_string_literal: true

module RBI
  extend T::Sig

  sig { returns(File) }
  def self.new
    File.new
  end

  class File
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
  end

  module Node
    extend T::Sig
    extend T::Helpers

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
      name
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

  class Call < Node
    extend T::Sig
    extend T::Helpers
    include Def

    abstract!

    sig { returns(String) }
    attr_reader :method

    sig { returns(T::Array[String]) }
    attr_reader :args

    sig { params(method: String, args: T::Array[String]).void }
    def initialize(method, args = [])
      @method = method
      @args = args
    end
  end

  class Module < Scope
    extend T::Sig

    sig { returns(T::Boolean) }
    attr_reader :is_interface

    sig { params(name: String, is_interface: T::Boolean).void }
    def initialize(name, is_interface: false)
      super(name)
      @is_interface = is_interface
    end
  end

  class Class < Scope
    extend T::Sig

    sig { returns(T::Boolean) }
    attr_reader :is_abstract

    sig { returns(T::Boolean) }
    attr_reader :is_sealed

    sig { returns(T.nilable(String)) }
    attr_reader :superclass

    sig do
      params(
        name: String,
        is_abstract: T::Boolean,
        is_sealed: T::Boolean,
        superclass: T.nilable(String)
      ).void
    end
    def initialize(name, is_abstract: false, is_sealed: false, superclass: nil)
      super(name)
      @is_abstract = is_abstract
      @is_sealed = is_sealed
      @superclass = superclass
    end
  end

  class Attr < Symbol
    extend T::Sig
    include Def

    sig { returns(T::Boolean) }
    attr_reader :is_setter

    sig { returns(T.nilable(String)) }
    attr_reader :type

    sig { returns(T::Array[Sig]) }
    attr_reader :sigs

    sig { params(name: String, is_setter: T::Boolean, type: T.nilable(String)).void }
    def initialize(name, is_setter: false, type: nil)
      super(name)
      @is_setter = is_setter
      @type = type
      @sigs = T.let([], T::Array[Sig])
      @sigs << default_sig if type
    end

    sig { returns(Sig) }
    def default_sig
      params = []
      params << Param.new(name, type: type) if is_setter
      Sig.new(params: params, returns: type)
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

    sig { returns(T.nilable(String)) }
    attr_reader :value

    sig { returns(T.nilable(String)) }
    attr_reader :type

    sig do
      params(
        name: String,
        is_keyword: T::Boolean,
        value: T.nilable(String),
        type: T.nilable(String)
      ).void
    end
    def initialize(name, is_keyword: false, value: nil, type: nil)
      super(name)
      @is_keyword = is_keyword
      @value = value
      @type = type
    end
  end

  class Ancestor
    extend T::Sig
    extend T::Helpers
    include Def

    abstract!

    sig { returns(String) }
    attr_reader :name

    sig { params(name: String).void }
    def initialize(name)
      @name = name
    end

    sig { returns(String) }
    def to_s
      name
    end
  end

  class Include < Ancestor
    extend T::Sig
  end

  class Extend < Ancestor
    extend T::Sig
  end

  class Prepend < Ancestor
    extend T::Sig
  end

  # Sorbet

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
