# typed: strict
# frozen_string_literal: true

class RBI
  module Parser
    extend T::Helpers
    extend T::Sig

    interface!

    sig { abstract.params(string: T.nilable(String)).returns(T.nilable(RBI)) }
    def parse_string(string); end

    sig { abstract.params(path: T.nilable(String)).returns(T.nilable(RBI)) }
    def parse_file(path); end
  end
end
