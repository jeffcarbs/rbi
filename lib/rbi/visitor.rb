# typed: strict
# frozen_string_literal: true

class RBI
  class Visitor
    extend T::Helpers
    extend T::Sig

    abstract!

    sig { params(rbis: T::Array[RBI]).void }
    def visit_rbis(rbis)
      rbis.each { |rbi| visit_rbi(rbi) }
    end

    sig { params(rbi: RBI).void }
    def visit_rbi(rbi)
      visit(rbi.root)
    end

    sig { abstract.params(node: T.nilable(Node)).void }
    def visit(node); end

    sig { params(scope: Scope).void }
    def visit_body(scope)
      visit_all(scope.body)
    end

    sig { params(nodes: T::Array[Node]).void }
    def visit_all(nodes)
      nodes.each { |node| visit(node) }
    end
  end
end
