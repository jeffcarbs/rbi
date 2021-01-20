# typed: true
# frozen_string_literal: true

class RBI
  class Progress
    extend T::Sig

    def initialize(max, size: 80, out: $stderr)
      @max = max
      @size = size
      @out = out
    end

    def tick(current)
      done = (current.to_f * @size.to_f / @max.to_f).round
      todo = ((@max - current).to_f * @size.to_f / @max.to_f).round
      @out.write("\r[#{'#' * done}#{'.' * todo}]")
    end

    def clear
      @out.write("\r")
    end
  end
end
