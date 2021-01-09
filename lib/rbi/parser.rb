# typed: strict
# frozen_string_literal: true

class RBI
  class Parser
    extend T::Sig

    # opt-in to most recent AST format:
    ::Parser::Builders::Default.emit_lambda   = true
    ::Parser::Builders::Default.emit_procarg0 = true
    ::Parser::Builders::Default.emit_encoding = true
    ::Parser::Builders::Default.emit_index    = true

    sig { params(paths: String).returns(T::Array[String]) }
    def self.list_files(*paths)
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

    sig { params(string: T.nilable(String)).returns(T.nilable(::AST::Node)) }
    def self.parse_string(string)
      return nil unless string
      ::Parser::CurrentRuby.parse(string)
    end

    sig { params(path: T.nilable(String)).returns(T.nilable(::AST::Node)) }
    def self.parse_file(path)
      return nil unless path
      ::Parser::CurrentRuby.parse_file(path)
    end
  end
end
