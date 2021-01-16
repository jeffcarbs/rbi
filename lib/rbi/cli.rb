# typed: true
# frozen_string_literal: true

class RBI
  # Command line interface
  class CLI < ::Thor
    extend T::Sig

    default_task :validate

    class_option :color, type: :boolean, default: true
    class_option :quiet, type: :boolean, default: false, aliases: :q
    class_option :verbose, type: :boolean, default: false, aliases: :v

    map T.unsafe(%w[--version] => :__print_version)

    desc 'validate', ''
    def validate(*paths)
      paths << '.' if paths.empty?
      files = T.unsafe(Parser).list_files(*paths)
      rbis = parse(files)
      rbis.each { |rbi| rbi.validate_duplicates }
    end

    desc 'format', ''
    def format(path, *paths)
      paths = [path, *paths]
      files = T.unsafe(Parser).list_files(*paths)
      rbis = parse(files)
      rbis.each { |rbi| puts rbi.to_rbi }
    end

    desc 'flatten', ''
    def flatten(path, *paths)
      paths = [path, *paths]
      files = T.unsafe(Parser).list_files(*paths)
      rbis = parse(files)
      rbis.each { |rbi| puts rbi.flatten.to_rbi }
    end

    desc '--version', 'Show version'
    def __print_version
      puts "RBI v#{RBI::VERSION}"
    end

    sig { returns(T::Boolean) }
    def self.exit_on_failure?
      true
    end

    no_commands do
      def logger
        level = T.unsafe(self).options[:verbose] ? Logger::DEBUG : Logger::INFO
        color = T.unsafe(self).options[:color]
        quiet = T.unsafe(self).options[:quiet]
        Logger.new(level: level, color: color, quiet: quiet)
      end

      def parse(files)
        logger = self.logger
        index = 0
        files.map do |file|
          logger.debug("Parsing #{file} (#{index}/#{files.size})")
          index += 1
          T.must(RBI.from_file(file))
        end
      end
    end
  end
end
