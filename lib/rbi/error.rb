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

    sig { params(section: Section).void }
    def <<(section)
      @sections << section
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

  class Logger
    extend T::Sig

    sig { params(error: Error).void }
    def show_error(error)
      loc = error.loc

      puts(ERROR, "\n#{loc}: #{colorize_message(error.message, :red)}")
      show_source(loc, indent_level: 1) if loc

      error.sections.each do |section|
        loc = section.loc
        puts(ERROR, "\n\t#{loc}: #{colorize_message(section.message, :yellow)}")
        show_source(loc, indent_level: 2) if loc
      end
    end

    private

    sig { params(loc: Loc, indent_level: Integer).void }
    def show_source(loc, indent_level: 0)
      file = loc.file
      return unless file

      puts(ERROR, "")
      indent = "\t" * indent_level

      string = File.read(file)
      lines = T.must(string.lines[(T.must(loc.range&.from&.line) - 1)..(T.must(loc.range&.to&.line) - 1)])
      lines = [
        *lines[1, 2],
        colorize("#{' ' * T.must(lines[2]&.index(/[^ ]/))}...", :light_black),
        *lines[-3..-2],
      ] if lines.size > 10
      lines.each do |line|
        puts(ERROR, "#{indent}#{colorize(line.rstrip, :light_black)}")
      end
    end

    sig { params(message: String, color: Symbol).returns(String) }
    def colorize_message(message, color)
      colorize(message, color).gsub(/`([^`]+)`/, colorize("\\1", :cyan))
    end
  end
end
