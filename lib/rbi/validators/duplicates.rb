# typed: strict
# frozen_string_literal: true

class RBI
  extend T::Sig

  # TODO transform as a visitor
  class Validator
    class Duplicates < Validator
      extend T::Sig

      sig { params(scopes_reopening: T::Boolean).void }
      def initialize(scopes_reopening: true)
        @scopes_reopening = scopes_reopening
      end

      sig { override.params(rbis: T::Array[RBI]).returns(T::Array[Error]) }
      def validate(rbis)
        errors = T.let([], T::Array[Error])
        index = RBI.index(rbis)
        index.each do |id, nodes|
          next unless nodes.size > 1
          first = T.must(nodes.first)

          not_scopes = nodes.select { |node| !node.is_a?(Scope) || node.is_a?(Def) }
          unless not_scopes.empty?
            error = Error.new("Duplicated definitions for `#{id}`. Defined here:", loc: first.loc)
            nodes.each do |node|
              next if node == first
              error.add_section("defined again here:", loc: node.loc)
            end
            errors << error
          end

          unless @scopes_reopening
            scopes = nodes - not_scopes
            next if scopes.empty?
            sizes = nodes.map do |node|
              T.cast(node, Scope).body.select { |child| !child.is_a?(Scope) || child.is_a?(Def) }.size
            end
            next unless sizes.select { |size| size != 0 }.size > 1
            error = Error.new("Duplicated definitions for `#{id}`. Defined here:", loc: first.loc)
            nodes.each do |node|
              next if node == first
              error.add_section("defined again here:", loc: node.loc)
            end
            errors << error
          end
        end
        errors
      end

      sig { override.params(node: T.nilable(Node)).void }
      def visit(node)
        # not used
      end
    end
  end
end
