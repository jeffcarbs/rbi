# typed: true
# frozen_string_literal: true

require "test_helper"

class RBI
  class SigsTemplatesTest < Minitest::Test
    include TestHelper

    def test_create_template_sigs_for_methods
      rbi = <<~RBI
        def foo; end
        def foo(a, b, c); end
        def foo(a, b:, c: "test"); end
        def foo(a = nil, b: nil, &c); end
      RBI
      assert_tpl_sigs_equal(<<~EXP, rbi)
        sig { returns(T.untyped) }
        def foo; end

        sig { params(a: T.untyped, b: T.untyped, c: T.untyped).returns(T.untyped) }
        def foo(a, b, c); end

        sig { params(a: T.untyped, b: T.untyped, c: T.untyped).returns(T.untyped) }
        def foo(a, b:, c: \"test\"); end

        sig { params(a: T.untyped, b: T.untyped, c: T.untyped).returns(T.untyped) }
        def foo(a = nil, b: nil, &c); end
      EXP
    end

    def test_create_template_sigs_for_attributes
      rbi = <<~RBI
        attr_reader :a
        attr_writer :b
        attr_accessor :c
      RBI
      assert_tpl_sigs_equal(<<~EXP, rbi)
        sig { returns(T.untyped) }
        attr_reader :a

        sig { params(b: T.untyped).void }
        attr_writer :b

        sig { params(c: T.untyped).returns(T.untyped) }
        attr_accessor :c
      EXP
    end

    def test_create_template_sigs_nested
      rbi = <<~RBI
        module Foo
          class Bar
            def foo(a, b, c); end
            attr_accessor :c
          end
        end
      RBI
      assert_tpl_sigs_equal(<<~EXP, rbi)
        module Foo
          class Bar
            sig { params(a: T.untyped, b: T.untyped, c: T.untyped).returns(T.untyped) }
            def foo(a, b, c); end

            sig { params(c: T.untyped).returns(T.untyped) }
            attr_accessor :c
          end
        end
      EXP
    end

    def test_does_not_recreate_signature
      rbi = <<~RBI
        sig { returns(String) }
        attr_reader :a

        sig { returns(Integer) }
        def foo; end
      RBI
      assert_tpl_sigs_equal(<<~EXP, rbi)
        sig { returns(String) }
        attr_reader :a

        sig { returns(Integer) }
        def foo; end
      EXP
    end

    private

    def assert_tpl_sigs_equal(exp, rbi)
      assert_equal(exp, parse(rbi).sigs_templates.to_rbi)
    end
  end
end
