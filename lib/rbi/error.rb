# typed: strict
# frozen_string_literal: true

class RBI
  class Error < StandardError
    extend T::Sig

    sig { returns(T.nilable(Loc)) }
    attr_reader :loc

    sig { returns(T::Array[Section]) }
    attr_reader :sections

    sig { params(message: String, loc: T.nilable(Loc)).void }
    def initialize(message, loc: nil)
      super(message)
      @loc = loc
      @sections = T.let([], T::Array[Section])
    end

    class Section
      extend T::Sig

      sig { returns(String) }
      attr_reader :message

      sig { returns(T.nilable(Loc)) }
      attr_reader :loc

      sig { params(message: String, loc: T.nilable(Loc)).void }
      def initialize(message, loc: nil)
        @message = message
        @loc = loc
      end
    end
  end
end
