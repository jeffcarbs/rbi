# typed: strict
# frozen_string_literal: true

require 'fileutils'
require 'json'
require 'open3'
require 'parser/current'
require 'sorbet-runtime'
require 'stringio'
require 'thor'

class RBI
  class Error < StandardError; end
end

require 'rbi/ast'
require 'rbi/printer'
require 'rbi/parser/base'
require 'rbi/parser/whitequark'
require 'rbi/parser/sorbet'
require 'rbi/parser'
# require 'rbi/rewriters/rewriter'
require 'rbi/rewriters/base'
require 'rbi/rewriters/flatten'
require 'rbi/version'
require 'rbi/cli'
