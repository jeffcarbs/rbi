# typed: true
# frozen_string_literal: true
$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))
require 'rbi'

class TestHelper
  extend T::Sig

  sig { params(string: String).returns(T.nilable(String)) }
  def parse_string(string)
    RBI.from_string(string).to_rbi
  end

  sig { params(exp: String, string: String).void }
  def assert_parse(exp, string)
    T.unsafe(self).assert_equal(exp, parse_string(string))
  end

  sig { params(string: String).void }
  def assert_identical(string)
    assert_parse(string, string)
  end
end

require 'minitest/autorun'
