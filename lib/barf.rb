require_relative "./barf/version"

require "mini_magick"
require_relative "./barf/rgb_to_ansi"
require "parallel"

module Barf

  def self.print(path)
    image = MiniMagick::Image.open(path)

    terminal_width = `tput cols`.to_i

    # Height must be divisible by 2 for the half pixels to be clean.
    new_height = [2, (image.height * (0.5 * terminal_width / image.width)).to_i * 2].max

    image.combine_options do |tmp|
      tmp.alpha 'remove'
      tmp.flatten
      tmp.resize "#{terminal_width}x#{new_height}!"

      # Only quantize to the 256-color ANSI palette when the terminal
      # doesn't support true color. This preserves full RGB fidelity
      # for terminals like iTerm2, Kitty, WezTerm, etc.
      unless Terminal.truecolor?
        tmp.remap __dir__ + '/palette.png'
      end
    end

    # Two dimensional array of pixels, processed two rows at a time
    # for the half-block character rendering.
    row_y = 0
    image.get_pixels.each_slice(2) do |top, bottom|
      out = Parallel.map_with_index(top) do |pixel, x|
        "\u2584".bg(pixel, x: x, y: row_y).fg(bottom[x], x: x, y: row_y + 1)
      end.join
      puts out
      row_y += 2
    end
    return nil
  end
end
