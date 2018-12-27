require_relative "./barf/version"

require "mini_magick"
require "tco"

module Barf

  def self.print(path)
    image = MiniMagick::Image.open(path)

    terminal_width = `tput cols`.to_i

    # Height must be divisible by 2 for the half pixels to be clean.
    new_height     = (image.height * (0.5 * terminal_width / image.width)).to_i * 2

    image.resize "#{terminal_width}x#{new_height}!"

    # Two dimensional array of pixels:
    image.get_pixels.each_slice(2) do |top, bottom|
      out = ""
      top.each_with_index do |pixel, index|
        out << "\u2584".bg(pixel).fg(bottom[index])
      end
      puts out
    end
    return nil
  end
end
