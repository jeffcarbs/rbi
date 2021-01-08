# typed: true
# frozen_string_literal: true

module RBI
  # Command line interface
  class CLI < ::Thor
    extend T::Sig

    map T.unsafe(%w[--version] => :__print_version)

    desc '--version', 'Show version'
    def __print_version
      puts "RBI v#{RBI::VERSION}"
    end

    def self.exit_on_failure?
      true
    end
  end
end
