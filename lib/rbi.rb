# typed: strict
# frozen_string_literal: true

require 'sorbet-runtime'
require 'thor'

require 'rbi/ast'
require 'rbi/printer'
require 'rbi/version'
require 'rbi/cli'

module RBI
  class Error < StandardError; end
end
