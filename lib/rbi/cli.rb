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
      index = Index.new

      paths << '.' if paths.empty?
      files = T.unsafe(Parser).list_files(*paths)
      rbis = parse(files)
      rbis.each do |rbi|
        index << rbi.root
      end

      v = Validators::Duplicates.new
      errors = v.validate(index)

      logger = self.logger
      errors.each do |error|
        logger.show_error(error)
      end
      if errors.empty?
        logger.say "No errors. Good job!"
      else
        logger.say "\n#{errors.size} errors"
      end
    end

    desc 'diff', ''
    def diff(*paths)
      paths << '.' if paths.empty?
      files = T.unsafe(Parser).list_files(*paths)
      files.each do |file|
        content_before = File.read(file)
        content_after = RBI.from_string(content_before)&.to_rbi(
          fold_empty_scopes: false,
          paren_includes: true,
          paren_mixes: true,
        )
        file1 = "#{file}.f1"
        file2 = "#{file}.f2"
        File.write(file1, content_before.gsub(/\n\n/, "\n"))
        File.write(file2, content_after&.gsub(/\n\n/, "\n"))
        system("diff -u #{file1} #{file2}")
        FileUtils.rm(file1)
        FileUtils.rm(file2)
      end
    end

    desc 'test', ''
    def test(*paths)
      paths << '.' if paths.empty?
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
