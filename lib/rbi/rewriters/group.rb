# typed: strict
# frozen_string_literal: true

class RBI
  extend T::Sig

  sig { returns(RBI) }
  def group
    v = Rewriters::Group.new
    v.visit_rbi(self)
    self
  end

  sig { params(rbis: RBI).void }
  def self.group(*rbis)
    v = Rewriters::Group.new
    v.visit_rbis(rbis)
  end

  module Rewriters
    class Group < Rewriter
      extend T::Sig

      sig { void }
      def initialize
        super()
      end

      sig { override.params(node: T.nilable(Node)).void }
      def visit(node)
        return unless node

        case node
        when Scope
          kinds = node.body.map(&:group_kind).uniq
          groups = {}
          kinds.each { |kind| groups[kind] = RBI::Group.new(kind) }

          node.body.dup.each do |child|
            visit(child)
            child.detach
            groups[child.group_kind] << child
          end

          groups.each { |_, group| node << group }
        end
      end
    end
  end

  class Node
    extend T::Sig

    sig { returns(Symbol) }
    def group_kind
      case self
      when Const
        :consts
      when Include, Prepend, Extend
        :includes
      when Interface, Abstract, MixesInClassMethods
        :sorbet
      when Attr
        :attrs
      when DefS
        :defss
      when Def
        :defs
      when NamedScope
        :scopes
      else
        raise "Unknown group for #{self}"
      end
    end
  end

  class Group < Scope
    extend T::Sig

    sig { returns(Symbol) }
    attr_reader :kind

    sig { params(kind: Symbol, loc: T.nilable(Loc)).void }
    def initialize(kind, loc: nil)
      super(loc: loc)
      @kind = kind
    end

    sig { override.params(v: Printer).void }
    def accept_printer(v)
      v.visit_scope(body)
    end
  end
end
