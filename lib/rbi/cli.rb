# typed: true
# frozen_string_literal: true

class RBI
  # Command line interface
  class CLI < ::Thor
    extend T::Sig

    default_task :rbi

    class_option :color, type: :boolean, default: true
    class_option :quiet, type: :boolean, default: false, aliases: :q
    class_option :verbose, type: :boolean, default: false, aliases: :v

    map T.unsafe(%w[--version] => :__print_version)

    # desc 'RBI', ''
    # def rbi(*paths)
    # paths << '.' if paths.empty?
    # puts "Listing files to parse..."
    # files = T.unsafe(Parser).list_files(*paths)
    # puts "  #{files.size} to parse."
    # files.each_with_index do |file, index|
    # puts "  parsing #{file} (#{index}/#{files.size})"
    # RBI.from_file(file)
    # end
    # # rbis.each { |rbi| print(rbi.to_rbi) }
    # end

    desc 'validate', ''
    def validate(*paths)
      paths << '.' if paths.empty?
      files = T.unsafe(Parser).list_files(*paths)
      files.map { |file| parse(file).validate_duplicates }
    end

    # desc 'format', ''
    # def format(*paths)
    # paths << '.' if paths.empty?
    # files = T.unsafe(Parser).list_files(*paths)
    # files.each do |file|
    # content_before = File.read(file)
    # content_after = RBI.from_string(content_before)&.to_rbi
    # ffile = "#{file}.f"
    # File.write(ffile, content_after)
    # system("diff -u #{file} #{ffile}")
    # FileUtils.rm(ffile)
    # end
    # end
    #
    # desc 'merge', ''
    # def merge(path1, path2, *paths)
    # rbi = RBI.from_file(path1)
    # [path2, *paths].each do |file|
    # rbi.index.pretty_print
    # rbi = rbi.merge(RBI.from_file(file))
    # end
    # puts rbi.to_rbi
    # end

    desc 'flatten', ''
    def flatten(path, *paths)
      files = [path, *paths]
      files.each do |file|
        puts RBI.from_file(file)&.flatten&.to_rbi
      end
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

      def parse(file)
        logger.debug("Parsing #{file}")
        T.must(RBI.from_file(file))
      end
    end
  end
end
