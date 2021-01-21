# typed: strict
# frozen_string_literal: true

require "colorize"
require 'fileutils'
require 'json'
require 'open3'
require 'parser/current'
require 'sorbet-runtime'
require 'stringio'
require 'thor'

require 'rbi/location'
require 'rbi/ast'

require 'rbi/visitor'
require 'rbi/index'
require 'rbi/metrics'
require 'rbi/printer'

require 'rbi/error'
require 'rbi/logger'
require 'rbi/progress'

require 'rbi/parser/base'
require 'rbi/parser/whitequark'
require 'rbi/parser/sorbet'
require 'rbi/parser'

require 'rbi/rewriters/base'
require 'rbi/rewriters/collect_sigs'
require 'rbi/rewriters/flatten'
require 'rbi/rewriters/inflate'
require 'rbi/rewriters/merge'
require 'rbi/rewriters/sigs_templates'
require 'rbi/rewriters/sort'

require 'rbi/validators/validator'
require 'rbi/validators/doc'
require 'rbi/validators/duplicates'
require 'rbi/validators/sigs'
require 'rbi/validators/tsig'
require 'rbi/validators'

require 'rbi/version'
require 'rbi/cli'
