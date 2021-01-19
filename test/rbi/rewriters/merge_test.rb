# typed: true
# frozen_string_literal: true

require "test_helper"

class RBI
  class MergeTest < Minitest::Test
    include TestHelper

    def test_merge_empty
      assert_merge_equal("", "", "")
    end

    # def test_merge_cbases
    # rbi1 = <<~RBI
    # include Foo
    # def foo; end
    # attr_reader :a
    # class A; end
    # RBI
    # rbi2 = <<~RBI
    # include Bar
    # def bar; end
    # attr_reader :b
    # module B; end
    # RBI
    # assert_merge_equal(<<~EXP, rbi1, rbi2)
    # include Foo
    # def foo; end
    # attr_reader :a
    # class A; end
    # include Bar
    # def bar; end
    # attr_reader :b
    # module B; end
    # EXP
    # end

    # def test_merge_discard_toplevel_duplicates
    # rbi1 = <<~RBI
    # include Foo
    # def foo; end
    # attr_reader :a
    # class A; end
    # RBI
    # rbi2 = <<~RBI
    # include Foo
    # def foo; end
    # attr_reader :a
    # class A; end
    # RBI
    # assert_merge_equal(<<~EXP, rbi1, rbi2)
    # include Foo
    # def foo; end
    # attr_reader :a
    # class A; end
    # EXP
    # end

    # def test_merge_discard_nested_duplicates
    # rbi1 = <<~RBI
    # class A
    # include Foo
    # def foo; end
    # attr_reader :a
    # class A; end
    # end
    # RBI
    # rbi2 = <<~RBI
    # class A
    # include Foo
    # def foo; end
    # attr_reader :a
    # class A; end
    # end
    # RBI
    # assert_merge_equal(<<~EXP, rbi1, rbi2)
    # class A
    # include Foo
    # def foo; end
    # attr_reader :a
    # class A; end
    # end
    # EXP
    # end

    # def test_merge_scopes
    # rbi1 = <<~RBI
    # module A
    # def a1; end
    # module B
    # def b1; end
    # module C
    # def c1; end
    # end
    # end
    # end
    # module A
    # def a2; end
    # module B
    # def b2; end
    # module C
    # def c2; end
    # end
    # end
    # end
    # RBI
    # rbi2 = <<~RBI
    # module A
    # def a1; end
    # module B
    # def b1; end
    # module C
    # def c1; end
    # end
    # end
    # end
    # module A
    # def a3; end
    # module B
    # def b3; end
    # module C
    # def c3; end
    # end
    # end
    # end
    # RBI
    # assert_merge_equal(<<~EXP, rbi1, rbi2)
    # module A
    # def a1; end
    #
    # module B
    # def b1; end
    #
    # module C
    # def c1; end
    # def c2; end
    # def c3; end
    # end
    #
    # def b2; end
    # def b3; end
    # end
    #
    # def a2; end
    # def a3; end
    # end
    # EXP
    # end

    private

    def assert_merge_equal(exp, rbi1, rbi2)
      assert_equal(exp, parse(rbi1).merge(parse(rbi2)).to_rbi)
    end
  end
end
