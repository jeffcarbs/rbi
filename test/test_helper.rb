# typed: true
# frozen_string_literal: true
$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))
require 'rbi'

class RBI
  module TestHelper
    extend T::Sig

    sig { params(string: String).returns(RBI) }
    def parse(string)
      T.must(RBI.from_string(string))
    end

    sig { params(exp: String, string: String).void }
    def assert_rbi_equals(exp, string)
      T.unsafe(self).assert_equal(exp, parse(string).to_rbi)
    end

    sig { params(string: String).void }
    def assert_rbi_same(string)
      assert_rbi_equals(string, string)
    end
  end
end

require 'minitest/autorun'
