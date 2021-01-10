# typed: strict
# frozen_string_literal: true

require 'fileutils'
require 'parser/current'
require 'sorbet-runtime'
require 'stringio'
require 'thor'

class RBI
  class Error < StandardError; end
end

require 'rbi/model'
require 'rbi/sorbet'
require 'rbi/printer'
require 'rbi/parser'
require 'rbi/version'
require 'rbi/cli'
