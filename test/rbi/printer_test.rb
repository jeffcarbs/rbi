# typed: true
# frozen_string_literal: true

require "test_helper"

module RBI
  class PrinterTest < Minitest::Test
    extend T::Sig
    # Scope

    def test_scope_nested
      rbi = RBI.new
      m = Module.new("M")
      m1 = Module.new("M1")
      m1 << Module.new("M11")
      m1 << Module.new("M12")
      m << m1
      m << Module.new("M2")
      rbi << m

      assert_equal(<<~RBI, rbi.to_rbi)
        module M
          module M1
            module M11; end
            module M12; end
          end

          module M2; end
        end
      RBI
    end

    def test_module
      rbi = RBI.new
      rbi << Module.new("M")

      assert_equal(<<~RBI, rbi.to_rbi)
        module M; end
      RBI
    end

    def test_module_with_modifiers
      rbi = RBI.new
      rbi << Module.new("M", interface: true)

      assert_equal(<<~RBI, rbi.to_rbi)
        module M
          interface!
        end
      RBI
    end

    def test_class
      rbi = RBI.new
      rbi << Class.new("C")

      assert_equal(<<~RBI, rbi.to_rbi)
        class C; end
      RBI
    end

    def test_class_with_modifiers
      rbi = RBI.new
      rbi << Class.new("C", superclass: "A", abstract: true, sealed: true)

      assert_equal(<<~RBI, rbi.to_rbi)
        class C < A
          abstract!
          sealed!
        end
      RBI
    end

    def test_class_with_superclass
      rbi = RBI.new
      rbi << Class.new("C", superclass: "A")

      assert_equal(<<~RBI, rbi.to_rbi)
        class C < A; end
      RBI
    end

    def test_tstruct
      rbi = RBI.new
      rbi << TStruct.new("C")

      assert_equal(<<~RBI, rbi.to_rbi)
        class C < T::Struct; end
      RBI
    end

    # Props

    def test_props
      rbi = RBI.new
      rbi << Const.new("FOO")
      rbi << Const.new("FOO", value: "42")
      rbi << AttrReader.new("foo")
      rbi << AttrAccessor.new("foo")
      rbi << Method.new("foo")
      rbi << Method.new("foo", params: [Param.new("a")])
      rbi << Method.new("foo", params: [Param.new("a"), Param.new("b"), Param.new("c")])
      rbi << Include.new("Foo")
      rbi << Extend.new("Foo")
      rbi << Prepend.new("Foo")

      assert_equal(<<~RBI, rbi.to_rbi)
        FOO
        FOO = 42
        attr_reader :foo
        attr_accessor :foo
        def foo; end
        def foo(a); end
        def foo(a, b, c); end
        include Foo
        extend Foo
        prepend Foo
      RBI
    end

    def test_props_nested
      rbi = RBI.new
      foo = Class.new("Foo")
      foo << Const.new("FOO")
      foo << Const.new("FOO", value: "42")
      foo << AttrReader.new("foo")
      foo << AttrAccessor.new("foo")
      foo << Method.new("foo")
      foo << Method.new("foo", params: [Param.new("a")])
      foo << Method.new("foo", params: [
        Param.new("a"),
        Param.new("b", value: "_"),
        Param.new("c", is_keyword: true),
        Param.new("d", is_keyword: true, value: "_"),
      ])
      foo << Include.new("Foo")
      foo << Extend.new("Foo")
      foo << Prepend.new("Foo")
      rbi << foo

      assert_equal(<<~RBI, rbi.to_rbi)
        class Foo
          FOO
          FOO = 42
          attr_reader :foo
          attr_accessor :foo
          def foo; end
          def foo(a); end
          def foo(a, b = _, c:, d: _); end
          include Foo
          extend Foo
          prepend Foo
        end
      RBI
    end

    # Sorbet

    def test_attr_sigs
      rbi = RBI.new
      rbi << AttrReader.new("foo")
      rbi << AttrReader.new("foo", type: nil)
      rbi << AttrReader.new("foo", type: "Foo")
      rbi << AttrAccessor.new("foo", type: "Foo")
      rbi << AttrAccessor.new("foo")

      assert_equal(<<~RBI, rbi.to_rbi)
        attr_reader :foo
        attr_reader :foo

        sig { returns(Foo) }
        attr_reader :foo

        sig { params(foo: Foo).returns(Foo) }
        attr_accessor :foo

        attr_accessor :foo
      RBI
    end

    def test_method_sigs
      rbi = RBI.new
      rbi << Method.new("foo")
      rbi << Method.new("foo", return_type: "String")
      rbi << Method.new("foo", params: [Param.new("a", type: "String")])
      rbi << Method.new("foo", params: [Param.new("a", type: "String")], return_type: "Integer")
      rbi << Method.new("foo", params: [
        Param.new("a", type: "String"),
        Param.new("b", value: "_", type: "String"),
        Param.new("c", is_keyword: true, type: "String"),
        Param.new("d", is_keyword: true, value: "_", type: "String"),
      ])

      assert_equal(<<~RBI, rbi.to_rbi)
        def foo; end

        sig { returns(String) }
        def foo; end

        sig { params(a: String).returns(T.untyped) }
        def foo(a); end

        sig { params(a: String).returns(Integer) }
        def foo(a); end

        sig { params(a: String, b: String, c: String, d: String).returns(T.untyped) }
        def foo(a, b = _, c:, d: _); end
      RBI
    end
  end
end
