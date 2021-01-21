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

    sig { params(message: String, loc: T.nilable(Loc)).void }
    def add_section(message, loc: nil)
      self << Section.new(message, loc: loc)
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

    sig { params(error: Error, compact: T::Boolean).void }
    def show_error(error, compact: false)
      loc = error.loc

      puts(ERROR, "#{loc}: #{colorize_message(error.message, :red)}")

      return if compact

      show_source(loc, indent_level: 1) if loc

      error.sections.each do |section|
        loc = section.loc
        puts(ERROR, "\t#{loc}: #{colorize_message(section.message, :yellow)}")
        show_source(loc, indent_level: 1) if loc
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
        *lines[..2],
        colorize("#{' ' * T.must(lines[2]&.index(/[^ ]/))}...", :light_black),
        *lines[-3..],
      ] if lines.size > 10
      lines.each do |line|
        puts(ERROR, "#{indent}#{colorize(line.rstrip, :light_black)}")
      end
      puts(ERROR, "")
    end

    sig { params(message: String, color: Symbol).returns(String) }
    def colorize_message(message, color)
      return message unless self.color
      res = StringIO.new
      buf = StringIO.new
      inside = T.let(false, T::Boolean)
      message.chars.each do |char|
        if char == '`'
          if inside
            res << colorize(buf.string, :cyan)
            buf = StringIO.new
            inside = false
          else
            res << colorize(buf.string, color)
            buf = StringIO.new
            inside = true
          end
          next
        end
        buf << char
      end
      res << colorize(buf.string, color)
      res.string
    end
  end
end
