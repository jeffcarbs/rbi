# typed: strict
# frozen_string_literal: true

class RBI
  class Logger
    extend T::Sig

    INTERNAL = 0
    ERROR = 1
    WARN = 2
    INFO = 3
    DEBUG = 4

    sig { returns(Integer) }
    attr_reader :level

    sig { returns(T::Boolean) }
    attr_reader :quiet

    sig { returns(T::Boolean) }
    attr_reader :colors

    sig { params(level: Integer, quiet: T::Boolean, colors: T::Boolean, out: IO).void }
    def initialize(level: INFO, quiet: false, colors: true, out: $stderr)
      @level = level
      @quiet = quiet
      @colors = colors
      @out = out
    end

    sig { params(message: String).void }
    def error(message)
      puts(ERROR, colorize("Error", :red), ": ", message)
    end

    sig { params(message: String).void }
    def warn(message)
      puts(WARN, colorize("Warning", :yellow), ": ", message)
    end

    sig { params(message: String).void }
    def info(message)
      puts(INFO, message)
    end

    sig { params(message: String).void }
    def debug(message)
      puts(DEBUG, colorize("Debug", :ligh_black), ": ", message)
    end

    sig { params(message: String).void }
    def say(message)
      puts(INTERNAL, message)
    end

    sig { params(string: String, color: Symbol).returns(String) }
    def colorize(string, color)
      return string unless @colors
      string.colorize(color)
    end

    private

    sig { params(level: Integer, string: String).void }
    def puts(level, *string)
      @out.puts string.join unless level > @level || @quiet
    end
  end
end
