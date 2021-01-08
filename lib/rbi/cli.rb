# typed: true
# frozen_string_literal: true

class RBI
  # Command line interface
  class CLI < ::Thor
    extend T::Sig

    default_task :rbi

    map T.unsafe(%w[--version] => :__print_version)

    desc 'RBI', ''
    def rbi(*paths)
      parser = Parser.new

      paths << '.' if paths.empty?
      files = parser.list_files(*paths)

      puts files

      # TODO list files
      # TODO parser files
      # TODO show result
    end

    desc '--version', 'Show version'
    def __print_version
      puts "RBI v#{RBI::VERSION}"
    end

    def self.exit_on_failure?
      true
    end
  end
end
