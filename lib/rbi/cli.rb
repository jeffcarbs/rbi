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

    # RBI rendering

    desc 'list', 'List RBIs'
    def list(*paths)
      paths << '.' if paths.empty?
      files = expand_paths(paths)
      files.each do |file|
        puts file
      end
    end

    desc 'metrics', 'Metrics about RBIs'
    def metrics(*paths)
      paths << '.' if paths.empty?
      files = expand_paths(paths)
      rbis = parse_files(files)
      metrics = RBI.metrics(rbis.map(&:last))
      metrics.pretty_print
    end

    desc 'show', 'Show RBI content'
    # TODO format
    # TODO options
    def show(*paths)
      files = expand_paths(paths)
      rbis = parse_files(files)
      logger = self.logger
      rbis.each do |file, rbi|
        puts logger.colorize("\n# #{file}\n", :light_black)
        puts rbi.to_rbi(
          color: color?,
          max_len: 100
        )
      end
    end

    desc 'suggest-sigs', 'Suggest RBIs signatures'
    def suggest_sigs(path, *paths)
      paths = [path, *paths]
      files = expand_paths(paths)
      rbis = parse_files(files)
      T.unsafe(RBI).collect_sigs(*rbis.map(&:last))
      T.unsafe(RBI).sigs_templates(*rbis.map(&:last))
      rbis.each do |rbi|
        puts rbi.last.to_rbi(
          color: color?,
          max_len: 100
        )
      end
    end

    # RBI edition

    desc 'merge', 'Merge RBIs together'
    def merge(path, *paths)
      paths = [path, *paths]
      files = expand_paths(paths)
      rbis = parse_files(files)
      puts T.unsafe(RBI).merge(*rbis.map(&:last)).to_rbi(color: color?)
    end

    desc 'flatten', 'Flatten RBIs'
    def flatten(path, *paths)
      paths = [path, *paths]
      files = expand_paths(paths)
      rbis = parse_files(files)
      puts T.unsafe(RBI).flatten(*rbis.map(&:last)).to_rbi(color: color?)
    end

    desc 'inflate', 'Inflate RBIs'
    def inflate(path, *paths)
      logger = self.logger
      paths = [path, *paths]
      files = expand_paths(paths)
      rbis = parse_files(files)
      inflated, errors = T.unsafe(RBI).inflate(*rbis.map(&:last))
      puts inflated.to_rbi(color: color?)
      logger.show_errors(errors)
      if errors.empty?
        logger.say("No errors. Good job!")
      else
        logger.say("#{errors.size} error#{errors.size > 1 ? 's' : ''}.")
      end
      exit(errors.empty?)
    end

    # RBI validation

    desc 'style', 'Check RBIs style'
    def style(*paths)
      paths << '.' if paths.empty?
      files = expand_paths(paths)
      files.each do |file|
        content_before = File.read(file)
        content_after = RBI.from_string(content_before)&.to_rbi(
          fold_empty_scopes: false,
          paren_includes: true,
          paren_mixes: true,
        )
        next if content_after&.empty?
        file1 = "#{file}.f1"
        file2 = "#{file}.f2"
        File.write(file1, content_before.gsub(/\n\n/, "\n"))
        File.write(file2, content_after&.gsub(/\n\n/, "\n"))
        system("diff -u #{file1} #{file2}")
        FileUtils.rm(file1)
        FileUtils.rm(file2)
      end
    end

    desc 'validate', 'Validate RBIs against a set of rules'
    option :short, type: :boolean, default: false, desc: 'Shortten the output'
    option :files, type: :boolean, default: false, desc: 'Show only files containing errors'
    option :forbid_scopes_reopen, type: :boolean, default: false, desc: ''
    option :forbid_tsig, type: :boolean, default: true, desc: 'Forbid usage of `extend T::Sig` in RBIs'
    option :require_sig, type: :boolean, default: false, desc: 'Require all methods to have a signature'
    option :require_doc, type: :boolean, default: false, desc: 'Require all methods to have documentation'
    def validate(*paths)
      paths << '.' if paths.empty?
      files = expand_paths(paths)
      rbis = parse_files(files).map(&:last)

      validators = []
      validators << Validators::Duplicates.new(scopes_reopening: !options[:forbid_scopes_reopen])
      validators << Validators::TSig.new if options[:forbid_tsig]
      validators << Validators::Doc.new if options[:require_doc]
      validators << Validators::Sigs.new if options[:require_sig]

      logger = self.logger
      errors = RBI.validate(rbis, validators: validators)

      if errors.empty?
        logger.say("No errors. Good job!")
        return
      end

      if options[:files]
        puts errors.map{ |error| error.loc&.file }.sort.uniq
      else
        errors.each do |error|
          logger.show_error(error, compact: options[:short])
        end
        logger.say("\n#{errors.size} errors")
      end
    end

    desc 'tc', 'Typecheck RBIs with Sorbet'
    def tc(path, *paths)
      paths = [path, *paths]
      run_sorbet(path)
    end

    # TODO test

    # Misc

    desc 'diff', 'Show diffs between two RBIs'
    def diff(file1, file2)
      rbis = parse_files([file1, file2])
      file1, file2 = rbis.map do |file, rbi|
        formatted = rbi.collect_sigs.flatten.sort
        ffile = "#{file}.formatted"
        File.write(ffile, formatted.to_rbi)
        ffile
      end
      out, _ = Open3.capture2("diff", "-u", file1, file2)
      FileUtils.rm(file1)
      FileUtils.rm(file2)

      logger = self.logger
      out.lines.each do |line|
        if line.start_with?("+")
          print(logger.colorize(line, :green))
        elsif line.start_with?("-")
          print(logger.colorize(line, :red))
        elsif line.start_with?("@")
          print(logger.colorize(line, :yellow))
        else
          print(line)
        end
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
        level = verbose? ? Logger::DEBUG : Logger::INFO
        quiet = T.unsafe(self).options[:quiet]
        Logger.new(level: level, color: color?, quiet: quiet)
      end

      def expand_paths(paths)
        T.unsafe(Parser).list_files(*paths)
      end

      def parse_files(files)
        logger = self.logger

        index = 0
        files.map do |file|
          logger.debug("Parsing #{file} (#{index}/#{files.size})")
          index += 1
          [file, T.must(RBI.from_file(file))]
        end
      end

      def run_sorbet(paths)
        T.unsafe(Open3).capture2("bundle", "exec", "srb", "tc", "--no-config", *paths)
      end

      # Options

      def color?
        T.unsafe(self).options[:color]
      end

      def verbose?
        T.unsafe(self).options[:verbose]
      end
    end
  end
end
