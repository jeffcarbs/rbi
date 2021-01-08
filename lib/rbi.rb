# typed: strict
# frozen_string_literal: true

require 'sorbet-runtime'
require 'thor'

require 'rbi/ast'
require 'rbi/parser'
require 'rbi/printer'
require 'rbi/version'
require 'rbi/cli'

class RBI
  class Error < StandardError; end
end
