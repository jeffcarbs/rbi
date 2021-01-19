# typed: strict
# frozen_string_literal: true
$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))
require 'rbi'

class RBI
  module TestHelper
    extend T::Sig

    sig { params(strings: String).returns([T::Boolean, T::Array[Validator::Error]]) }
    def validate(*strings)
      rbis = strings.map { |string| parse(string) }
      RBI.validate(rbis)
    end

    sig { params(string: String).returns(RBI) }
    def parse(string)
      T.must(RBI.from_string(string))
    end

    sig { params(exp: String, string: String).void }
    def assert_rbi_equal(exp, string)
      T.unsafe(self).assert_equal(exp, parse(string).to_rbi)
    end

    sig { params(string: String).void }
    def assert_rbi_same(string)
      assert_rbi_equal(string, string)
    end
  end
end

require 'minitest/autorun'
