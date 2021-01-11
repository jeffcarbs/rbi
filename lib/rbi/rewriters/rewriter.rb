# typed: strict
# frozen_string_literal: true

class RBI
  class Rewriter
    extend T::Sig
    extend T::Helpers

    abstract!

    sig { abstract.params(rbi: RBI).returns(RBI) }
    def rewrite(rbi); end
  end

end
