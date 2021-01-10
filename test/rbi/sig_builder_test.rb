# typed: true
# frozen_string_literal: true

require "test_helper"

class RBI
  class SigBuilderTest < Minitest::Test
    extend T::Sig

    sig { params(string: String).returns(String) }
    def parse_sig(string)
      SigBuilder.parse(string).to_rbi
    end

    sig { params(exp: String, string: String).void }
    def assert_parse(exp, string)
      assert_equal(exp, parse_sig(string))
    end

    sig { params(string: String).void }
    def assert_parse_identical(string)
      assert_parse(string, string)
    end

    # Tests

    def test_parse_empty
      assert_nil(SigBuilder.parse(""))
    end

    def test_parse_empty_sig
      assert_parse_identical("sig {  }\n")
    end
  end
end
