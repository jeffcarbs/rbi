# typed: strict
# frozen_string_literal: true

class RBI
  class Rewriter < Visitor
    extend T::Helpers

    abstract!
  end

  class Scope
    extend T::Sig

    sig { returns(Scope) }
    def dup_empty
      case self
      when CBase
        CBase.new
      when Module
        Module.new(name, loc: loc)
      when Class
        Class.new(name, superclass: superclass, loc: loc)
      when SClass
        SClass.new(loc: loc)
      else
        raise
      end
    end

    sig { returns(Scope) }
    def stub_empty
      case self
      when CBase
        CBase.new
      when Module
        Module.new(name, loc: loc)
      when Class
        Class.new(name, loc: loc)
      when SClass
        SClass.new(loc: loc)
      else
        raise
      end
    end
  end
end
