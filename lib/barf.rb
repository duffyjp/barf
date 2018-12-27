require_relative "./barf/version"

require "mini_magick"
require "tco"
require "parallel"

module Barf

  @palette = "inline:data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAP4AAAABCAIAAABxMITKAAABpklEQVR4AW2StWIUXRTHf2d2o9+Huzv85yGooKJKic7wKukueYvZICXW0kZ67CwV7lbh7CVzd+IZ/dv1Y8Dw8PDo8uvYzHSnsIJ4oyrPQafk1KtXfWtoaKjVarXb7cHBwTm6aWJiM2wHwQZjVySUCEtPL1SliDU2QoFoHlPFARihdENWqWcZRc+qWwWy0iOiGqusW8YTlFR4iaLC5ObNbP8cXWkIjyJz9UQW6m8zbrh1SZAyyFnAYayqsRfCGpdq/Rt27mo/8YsiujhO3JjlQ1FG6wwPQVXpg+gcDrpXaQidxMl095KPoNNJVyeI6JarR5vW0eyhIh6VVu0CNykiEkaC0JGiOScEosmst9e72R0uLTbJ8RPg1DjLA2mWJvjeLp49sESjmEx7YQlf9kXcCfV3o+urKLtO3Zdo8qmrDa9t1+5LvrhNh8bH+0fcP+5N7965Un+ufuTQz58LgbnvztlZRTxHsJARFvQ44TRHl4zuCU6A3JNe465rAV8JDV7eT8qvpYfcFdMql+s7ZmYWqvTY37/NQF0p4mLdq1eZZcMjw5s2bfoHC6PO/+pdxgEAAAAASUVORK5CYII="

  def self.print(path)
    image = MiniMagick::Image.open(path)

    terminal_width = `tput cols`.to_i

    # Height must be divisible by 2 for the half pixels to be clean.
    new_height     = [2, (image.height * (0.5 * terminal_width / image.width)).to_i * 2].max

    image.combine_options do |tmp|
      tmp.alpha 'remove'
      tmp.resize "#{terminal_width}x#{new_height}!"
      tmp.dither 'FloydSteinberg'
      tmp.remap @palette
    end

    # Two dimensional array of pixels:
    image.get_pixels.each_slice(2) do |top, bottom|
      out = Parallel.map_with_index(top) do |pixel, index|
        "\u2584".bg(pixel).fg(bottom[index])
      end.join
      puts out
    end
    return nil
  end
end
