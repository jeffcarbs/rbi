# typed: strict
# frozen_string_literal: true

class RBI
  class Rewriter < Visitor
    extend T::Helpers

    abstract!

    class Error < RBI::Error; end
  end

  class Stmt
    extend T::Sig

    sig { void }
    def detach
      T.must(self.parent_scope).body.delete(self)
      self.parent_scope = nil
    end
  end

  class Scope
    extend T::Sig

    sig { returns(T.self_type) }
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

    sig { returns(T.self_type) }
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
