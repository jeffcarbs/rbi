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
      rbis = parse_rbis(paths)
      rbis.each { |rbi| print rbi.to_rbi }
    end

    desc 'format', ''
    def format(*paths)
      rbis = parse_rbis(paths)
      rbis.each { |rbi| print rbi.to_rbi }
    end

    desc '--version', 'Show version'
    def __print_version
      puts "RBI v#{RBI::VERSION}"
    end

    def self.exit_on_failure?
      true
    end

    no_commands do
      def parse_rbis(*paths)
        paths << '.' if paths.empty?
        files = T.unsafe(Parser).list_files(*paths)
        files.map { |file| RBI.from_file(file) }
      end
    end
  end
end
