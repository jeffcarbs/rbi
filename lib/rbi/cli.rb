# typed: ignore
# frozen_string_literal: true

class RBI
  # Command line interface
  class CLI < ::Thor
    extend T::Sig

    default_task :rbi

    map T.unsafe(%w[--version] => :__print_version)

    desc 'RBI', ''
    def rbi(*paths)
      paths << '.' if paths.empty?
      files = T.unsafe(Parser).list_files(*paths)
      rbis = files.map { |file| RBI.from_file(file) }
      rbis.each { |rbi| print(rbi.to_rbi) }
    end

    desc 'compile', ''
    def compile(*paths)
      paths << '.' if paths.empty?
      files = T.unsafe(Parser).list_files(*paths)
      files.map { |file| RBI.from_file(file) }
      puts "Compiled correctly. Good job!"
    end

    desc 'format', ''
    def format(*paths)
      paths << '.' if paths.empty?
      files = T.unsafe(Parser).list_files(*paths)
      files.each do |file|
        content_before = File.read(file)
        content_after = RBI.from_string(content_before).to_rbi
        ffile = "#{file}.f"
        File.write(ffile, content_after)
        system("diff -u #{file} #{ffile}")
        FileUtils.rm(ffile)
      end
    end

    desc '--version', 'Show version'
    def __print_version
      puts "RBI v#{RBI::VERSION}"
    end

    def self.exit_on_failure?
      true
    end

    no_commands do
      def parse_rbi_files(paths)
      end
    end
  end
end
