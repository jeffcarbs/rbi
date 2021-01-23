# typed: true
# frozen_string_literal: true

require "test_helper"

class RBI
  class GroupTest < Minitest::Test
    include TestHelper

    def test_group_empty
      assert_group_equal("", "")
    end

    def test_group_sclass_body
      rbi = <<~RBI
        class A; end
        include B
        attr_reader :c
        module D; end
        class E; end
        def g; end
        attr_accessor :h
        mixes_in_class_methods I
        K = 10
        module L; end
        extend M
        def self.n; end
      RBI
      assert_group_equal(<<~EXP, rbi)
        class A; end
        module D; end
        class E; end
        module L; end

        include B
        extend M

        attr_reader :c
        attr_accessor :h

        def g; end

        mixes_in_class_methods I

        K = 10

        def self.n; end
      EXP
    end

    def test_group_sclass_body_and_sort
      rbi = <<~RBI
        class A; end
        include B
        attr_reader :c
        module D; end
        class E; end
        def g; end
        attr_accessor :h
        mixes_in_class_methods I
        K = 10
        module L; end
        extend M
        def self.n; end
        abstract!
        interface!
      RBI
      assert_group_equal(<<~EXP, rbi, sort: true)
        extend M
        include B

        abstract!
        interface!
        mixes_in_class_methods I

        K = 10

        attr_reader :c
        attr_accessor :h

        def self.n; end

        def g; end

        class A; end
        module D; end
        class E; end
        module L; end
     EXP
    end

    def test_group_nested_body_and_sort
      rbi = <<~RBI
        class C1
          class A; end
          include B
          attr_reader :c
          module D; end
          class E; end
        end

        class C2
          def g; end
          attr_accessor :h
          mixes_in_class_methods I
          class << self
            K = 10
            module L; end
            extend M
            def self.n; end
          end
        end
      RBI
      assert_group_equal(<<~EXP, rbi, sort: true)
        class C1
          include B

          attr_reader :c

          class A; end
          module D; end
          class E; end
        end

        class C2
          mixes_in_class_methods I

          attr_accessor :h

          def g; end

          class << self
            extend M

            K = 10

            def self.n; end

            module L; end
          end
        end
     EXP
    end

    private

    def assert_group_equal(exp, rbi, sort: false)
      new = parse(rbi).group
      new = new.sort if sort
      assert_equal(exp, new.to_rbi)
    end
  end
end
