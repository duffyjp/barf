require_relative "./barf/version"

require "mini_magick"
require "tco"
require "parallel"

module Barf

  def self.print(path)
    image = MiniMagick::Image.open(path)

    terminal_width = `tput cols`.to_i

    # Height must be divisible by 2 for the half pixels to be clean.
    new_height     = [2, (image.height * (0.5 * terminal_width / image.width)).to_i * 2].max

    image.combine_options do |tmp|
      tmp.alpha 'remove'
      tmp.flatten
      tmp.resize "#{terminal_width}x#{new_height}!"
      tmp.dither 'FloydSteinberg'
      tmp.remap __dir__ + '/palette.png'
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
