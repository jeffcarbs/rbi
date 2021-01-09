# typed: true
# frozen_string_literal: true

require "test_helper"

class RBI
  class ValueBuilderTest < Minitest::Test
    extend T::Sig

    sig { params(string: String).returns(T.nilable(String)) }
    def parse_name(string)
      ValueBuilder.parse_string(string)
    end

    sig { params(exp: String, string: String).void }
    def assert_parse(exp, string)
      assert_equal(exp, parse_name(string))
    end

    sig { params(string: String).void }
    def assert_identical(string)
      assert_parse(string, string)
    end

    # Tests

    def test_parse_error
      assert_nil(parse_name(""))
      assert_nil(parse_name(";"))
    end

    def test_parse_literals
      assert_identical("0")
      assert_identical("\"foo\"")
      assert_identical("nil")
      assert_identical("-10")
      assert_parse("10.*(10)", "10 * 10")
      assert_parse("\"foo\"", "'foo'")
    end

    def test_parse_names
      assert_identical("_")
      assert_identical("a")
      assert_identical("A")
      assert_identical("foo")
      assert_identical("Foo")
      assert_identical("foo10")
      assert_identical("Foo10")
      assert_identical("_foo")
      assert_identical("_Foo")
    end

    def test_parse_qnames
      assert_identical("A::A")
      assert_identical("Foo::Foo")
      assert_identical("Foo10::Foo10")
    end

    def test_parse_qsends
      assert_parse("_._", "_::_")
      assert_parse("a.a", "a::a")
      assert_parse("Foo.foo", "Foo::foo")
      assert_parse("foo.foo", "foo::foo")
      assert_parse("foo10.foo10", "foo10::foo10")
      assert_parse("_foo._foo", "_foo::_foo")
      assert_parse("_Foo._Foo", "_Foo::_Foo")
      assert_parse("_.a::A::Foo.foo._foo._Foo10", "_::a::A::Foo::foo::_foo::_Foo10")
    end

    def test_parse_indexes
      assert_identical("Foo[A, B, C]")
      assert_identical("Foo::Bar[A, B, C]")
      assert_identical("Foo(A, B, C)")
      assert_identical("Foo.Bar(A, B, C)")
      assert_identical("Foo.bar(A, B, C)")
      assert_identical("Foo::Bar.bar(A, B, C)")
    end

    def test_parse_cbase
      assert_identical("::A")
      assert_identical("::A::Foo::FOO")
      assert_identical("::Foo.a")
      assert_identical("::Foo.foo.bar")
      assert_identical("::Foo.foo(A, B, C)")
      assert_parse("::Foo.a", "::Foo::a")
      assert_parse("::Foo.foo.bar(A, B, C)", "::Foo::foo.bar(A, B, C)")
    end
  end
end
