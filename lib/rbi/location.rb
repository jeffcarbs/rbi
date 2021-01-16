# typed: strict
# frozen_string_literal: true

class RBI
  class Loc
    extend T::Sig

    sig { returns(T.nilable(String)) }
    attr_reader :file

    sig { returns(T.nilable(Range)) }
    attr_reader :range

    sig { params(file: T.nilable(String), range: T.nilable(Range)).void }
    def initialize(file = nil, range = nil)
      @file = file
      @range = range
    end

    sig { returns(String) }
    def to_s
      "#{file}:#{range}"
    end
  end

  class Range
    extend T::Sig

    sig { returns(Pos) }
    attr_reader :from, :to

    sig { params(from: Pos, to: Pos).void }
    def initialize(from, to)
      @from = from
      @to = to
    end

    sig { returns(String) }
    def to_s
      "#{from}-#{to}"
    end
  end

  class Pos
    extend T::Sig

    sig { returns(Integer) }
    attr_reader :line, :column

    sig { params(line: Integer, column: Integer).void }
    def initialize(line, column)
      @line = line
      @column = column
    end

    sig { returns(String) }
    def to_s
      "#{line}:#{column}"
    end
  end
end
