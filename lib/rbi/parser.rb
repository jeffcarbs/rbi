# typed: strict
# frozen_string_literal: true

class RBI
  extend T::Sig

  sig { params(string: String, parser: Parser).returns(T.nilable(RBI)) }
  def self.from_string(string, parser: Parser::Whitequark.new)
    Parser.parse_string(string, parser: parser)
  end

  sig { params(path: String, parser: Parser).returns(T.nilable(RBI)) }
  def self.from_file(path, parser: Parser::Whitequark.new)
    Parser.parse_file(path, parser: parser)
  end

  module Parser
    class << self
      extend T::Sig

      sig { params(paths: String).returns(T::Array[String]) }
      def list_files(*paths)
        files = T.let([], T::Array[String])
        paths.each do |path|
          unless ::File.exist?(path)
            $stderr.puts("can't find `#{path}`.")
            next
          end
          if ::File.directory?(path)
            files = files.concat(Dir.glob(Pathname.new("#{path}/**/*.rbi").cleanpath))
          else
            files << path
          end
        end
        files.uniq.sort
      end

      sig { params(string: String, parser: Parser).returns(T.nilable(RBI)) }
      def parse_string(string, parser: Whitequark.new)
        parser.parse_string(string)
      end

      sig { params(path: String, parser: Parser).returns(T.nilable(RBI)) }
      def parse_file(path, parser: Whitequark.new)
        parser.parse_file(path)
      end
    end
  end
end
