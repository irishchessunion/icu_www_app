module Util
  class Diff
    def initialize(a, b)
      @a = to_s(a)
      @b = to_s(b)
    end

    # Show where the difference is between two strings within a certain limit.
    def difference(limit=255, context=10)
      if (@a.length <= limit && @b.length <= limit) || @a == @b
        [@a.truncate(limit), @b.truncate(limit)]
      else
        find_diff(limit, context)
      end
    end

    private

    def to_s(obj)
      case obj
      when DateTime then obj.to_fs(:db)
      else obj.to_s
      end
    end

    def find_diff(limit, context)
      a = @a
      b = @b
      amax = a.length - 1
      bmax = b.length - 1
      index = 0

      # Find the first occurence of any difference.
      while a[index] == b[index] && index <= amax && index <= bmax
        index += 1
      end

      # Wind back the index to give a bit of context for where the difference occurs.
      index = index > context ? index - context : 0

      # Replace the equal parts with a short mask, in new strings, as the originals may be frozen (nil.to_s)
      # or be the record's own attribute values.
      mask = '.' * (index > 3 ? 3 : index)
      a = mask + a[index..].to_s
      b = mask + b[index..].to_s

      # Truncate and return them.
      [a.truncate(limit), b.truncate(limit)]
    end
  end
end
