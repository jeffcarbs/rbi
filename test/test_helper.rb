# typed: strict
# frozen_string_literal: true
$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))
require 'rbi'

class RBI
  module TestHelper
    extend T::Sig

    sig { params(strings: String, opts: T::Hash[Symbol, T.untyped]).returns(String) }
    def print(*strings, opts: {})
      rbis = strings.map { |string| parse(string) }
      rbis.map { |rbi| T.unsafe(rbi).to_rbi(**opts) }.join("\n\n")
    end

    sig { params(strings: String, validators: T::Array[Validator]).returns(T::Array[Validator::Error]) }
    def validate(*strings, validators: RBI.default_validators)
      rbis = strings.map { |string| parse(string) }
      RBI.validate(rbis, validators: validators)
    end

    sig { params(string: String).returns(RBI) }
    def parse(string)
      T.must(RBI.from_string(string))
    end

    sig { params(exp: String, string: String, opts: T::Hash[Symbol, T.untyped]).void }
    def assert_rbi_equal(exp, string, opts: {})
      T.unsafe(self).assert_equal(exp, print(string, opts: opts))
    end

    sig { params(string: String, opts: T::Hash[Symbol, T.untyped]).void }
    def assert_rbi_same(string, opts: {})
      assert_rbi_equal(string, string, opts: opts)
    end
  end
end

require 'minitest/autorun'
