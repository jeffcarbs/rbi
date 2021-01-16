# typed: true

# A
class A # A

  # B

  # B
  class B
    class C
      # eTSig
      extend T::Sig # eTSig2

      # foo

      # foo
      def foo; end # foo
    end

    #
    ##
    # bar

    def bar; end # bar
  end

  def baz # foo
    # baz
  end # baz
end # A

# main
def main; end
