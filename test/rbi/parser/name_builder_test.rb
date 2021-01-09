# typed: true
# frozen_string_literal: true

require "test_helper"

class RBI
  class NameBuilderTest < Minitest::Test
    extend T::Sig

    sig { params(string: String).returns(T.nilable(String)) }
    def parse_name(string)
      NameBuilder.parse_string(string)
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

    def test_parse_empty
      assert_nil(parse_name(""))
    end

    def test_parse_error
      assert_nil(parse_name(";"))
      assert_nil(parse_name("10"))
      assert_nil(parse_name("-10"))
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
      assert_identical("_::_")
      assert_identical("a::a")
      assert_identical("A::A")
      assert_identical("foo::foo")
      assert_identical("Foo::Foo")
      assert_identical("foo10::foo10")
      assert_identical("Foo10::Foo10")
      assert_identical("_foo::_foo")
      assert_identical("_Foo::_Foo")
      assert_identical("_::a::A::Foo::foo::_foo::_Foo10")
    end

    def test_parse_only_names
      assert_parse("Foo", "Foo[A, B, C]")
      assert_parse("Foo::Bar", "Foo::Bar[A, B, C]")
      assert_parse("Foo", "Foo(A, B, C)")
      assert_parse("Foo::Bar", "Foo::Bar(A, B, C)")
      assert_parse("Foo::bar", "Foo.bar(A, B, C)")
      assert_parse("Foo::Bar::bar", "Foo::Bar.bar(A, B, C)")
    end

    def test_parse_cbase
      assert_identical("::A")
      assert_identical("::A::Foo::FOO")
      assert_identical("::Foo::a")
      assert_identical("::Foo::foo")
      assert_parse("::Foo::foo::bar", "::Foo::foo.bar")
    end

    def test_parse_consts
      assert_parse("F", "F = 10")
      assert_parse("FOO", "FOO = FOO")
      assert_parse("F::F::F", "F::F::F = FOO")
      assert_parse("::Foo", "::Foo = FOO")
    end
  end
end
