# typed: strict
# frozen_string_literal: true

class RBI
  module Parser
    extend T::Helpers
    extend T::Sig

    interface!

    sig { abstract.params(string: String).returns(T.nilable(RBI)) }
    def parse_string(string); end

    sig { abstract.params(path: String).returns(T.nilable(RBI)) }
    def parse_file(path); end

    class Error < RBI::Error; end
  end
end
