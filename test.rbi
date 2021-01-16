# typed: true

# Foo
class A

  # Bar
  class B
    class C
      extend T::Sig
      def foo; end
    end

    #
    ##
    # foo

    def foo; end # foo
  end

  def foo # foo
    # foo
  end # foo
end # foo

def foo; end
