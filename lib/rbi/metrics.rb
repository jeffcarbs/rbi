# typed: strict
# frozen_string_literal: true

class RBI
  extend T::Sig

  sig { returns(Metrics) }
  def metrics
    RBI.metrics([self])
  end

  sig { params(rbis: T::Array[RBI]).returns(Metrics) }
  def self.metrics(rbis)
    v = MetricsCollector.new
    v.visit_all(rbis.map(&:root))
    v.metrics
  end

  class Metrics < T::Struct
    extend T::Sig

    prop :modules, Integer, default: 0
    prop :classes, Integer, default: 0
    prop :sclasses, Integer, default: 0
    prop :defs, Integer, default: 0
    prop :sigs, Integer, default: 0
    prop :attrs, Integer, default: 0
    prop :consts, Integer, default: 0
    prop :sends, Integer, default: 0

    sig { void }
    def pretty_print
      puts "* modules\t#{modules}"
      puts "* classes\t#{classes}"
      puts "* sclasses\t#{sclasses}"
      puts "* defs\t\t#{defs}"
      puts "* sigs\t\t#{sigs}"
      puts "* attrs\t\t#{attrs}"
      puts "* consts\t#{consts}"
      puts "* sends\t\t#{sends}"
    end
  end

  class MetricsCollector < Visitor
    extend T::Sig

    sig { returns(Metrics) }
    attr_reader :metrics

    sig { void }
    def initialize
      super()
      @metrics = T.let(Metrics.new, Metrics)
    end

    sig { override.params(node: T.nilable(Node)).void }
    def visit(node)
      case node
      when Module
        metrics.modules += 1
        visit_all(node.body)
      when SClass
        metrics.sclasses += 1
        visit_all(node.body)
      when Class
        metrics.classes += 1
        visit_all(node.body)
      when Def
        metrics.defs += 1
        visit_all(node.body)
      when Attr
        metrics.attrs += 1
      when Const
        metrics.consts += 1
      when Sig
        metrics.sigs += 1
      when Send
        metrics.sends += 1
      end
    end
  end
end
