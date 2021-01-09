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

require 'rbi/nodes'
require 'rbi/printer'
require 'rbi/parser'

# require 'rbi/ast'
require 'rbi/sig_builder'
require 'rbi/parser/name_builder'
require 'rbi/parser/value_builder'
require 'rbi/builder'

require 'rbi/version'
require 'rbi/cli'
