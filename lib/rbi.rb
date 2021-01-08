# typed: strict
# frozen_string_literal: true

require 'fileutils'
require 'sorbet-runtime'
require 'stringio'
require 'thor'

class RBI
  class Error < StandardError; end
end

require 'rbi/ast'
require 'rbi/parser'
require 'rbi/builder'
require 'rbi/printer'
require 'rbi/version'
require 'rbi/cli'
