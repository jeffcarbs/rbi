# typed: true
# frozen_string_literal: true

class RBI
  # Command line interface
  class CLI < ::Thor
    extend T::Sig

    default_task :rbi

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
      files.map { |file| T.must(RBI.from_file(file)).validate_duplicates }
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
  end
end
