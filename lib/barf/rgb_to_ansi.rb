# frozen_string_literal: true

##
# A helper module to detect terminal capabilities.
module Terminal
  # Checks if the terminal likely supports 24-bit "true color" by checking
  # the standard COLORTERM environment variable.  Works in iTerm, MacOS Terminal does not as of 2025.
  def self.truecolor?
    ENV['COLORTERM'] =~ /^(truecolor|24bit)$/
  end
end

##
# Converts an RGB color to the nearest matching 8-bit ANSI terminal color code.
# This is now only used as a fallback for terminals without true color support.
class AnsiColorConverter
  # Pre-calculated lookup table of the 256 ANSI colors and their RGB values.
  ANSI_PALETTE = begin
                   cube_levels = [0, 95, 135, 175, 215, 255]
                   palette = [
                     [0, 0, 0], [128, 0, 0], [0, 128, 0], [128, 128, 0],
                     [0, 0, 128], [128, 0, 128], [0, 128, 128], [192, 192, 192],
                     [128, 128, 128], [255, 0, 0], [0, 255, 0], [255, 255, 0],
                     [0, 0, 255], [255, 0, 255], [0, 255, 255], [255, 255, 255]
                   ]
                   (0..5).each { |r| (0..5).each { |g| (0..5).each { |b| palette << [cube_levels[r], cube_levels[g], cube_levels[b]] } } }
                   (0..23).each { |step| level = 8 + (step * 10); palette << [level, level, level] }
                   palette.freeze
                 end.freeze

  # A fixed binary string used for deterministic dithering. Prime length (97)
  # avoids repeating in sync with common image widths. Each row starts at
  # offset (7 * y) to prevent horizontal banding between rows.
  DITHER_PATTERN = "0110100011010110101000110101101001011010001101100101101000101101011010110100011010100110100101101".freeze

  # Deterministic dither decision based on pixel coordinates.
  # Thread-safe since it uses only the immutable pattern string.
  def self.dither?(x, y)
    DITHER_PATTERN[(x + 7 * y) % DITHER_PATTERN.length] == "1"
  end

  # Finds the nearest ANSI 256-color code for the given RGB value.
  # Uses the dither pattern at (x, y) to choose between the nearest and
  # second-nearest match, simulating organic dithering deterministically.
  def self.convert(r, g, b, x: 0, y: 0)
    use_alternate = dither?(x, y)

    min_dist_sq = Float::INFINITY
    alternate_code = 0
    nearest_code = 0
    ANSI_PALETTE.each_with_index do |(ar, ag, ab), code|
      dist_sq = (r - ar)**2 + (g - ag)**2 + (b - ab)**2
      next unless dist_sq < min_dist_sq
      alternate_code = nearest_code
      min_dist_sq = dist_sq
      nearest_code = code
    end

    use_alternate ? alternate_code : nearest_code
  end
end

##
# Extend Ruby's String class to add terminal color methods.
class String
  # Matches an ANSI-wrapped string to allow for code chaining.
  ANSI_COLOR_REGEX = /\A(\e\[[\d;]*m)(.*?)(\e\[0m)\z/m

  # Sets the foreground color of the string using an RGB array.
  # @param rgb_array [Array<Integer>] An array of [r, g, b] values (0-255).
  # @param x [Integer] Pixel x coordinate for deterministic dithering.
  # @param y [Integer] Pixel y coordinate for deterministic dithering.
  # @return [String] The colorized string.
  def fg(rgb_array, x: 0, y: 0)
    apply_color('38', rgb_array, x: x, y: y)
  end

  # Sets the background color of the string using an RGB array.
  # @param rgb_array [Array<Integer>] An array of [r, g, b] values (0-255).
  # @param x [Integer] Pixel x coordinate for deterministic dithering.
  # @param y [Integer] Pixel y coordinate for deterministic dithering.
  # @return [String] The colorized string.
  def bg(rgb_array, x: 0, y: 0)
    apply_color('48', rgb_array, x: x, y: y)
  end

  private

  # Helper method to apply an ANSI color code to the string.
  # It intelligently handles chained calls by combining ANSI codes.
  def apply_color(type_code, rgb_array, x: 0, y: 0)
    color_segment =
      if Terminal.truecolor?
        # Use 24-bit "true color" for perfect quality.
        "#{type_code};2;#{rgb_array.join(';')}"
      else
        # Fallback to the 256-color palette for older terminals.
        ansi_code = AnsiColorConverter.convert(*rgb_array, x: x, y: y)
        "#{type_code};5;#{ansi_code}"
      end

    if (match = match(ANSI_COLOR_REGEX))
      # String is already colorized, so we combine new and existing codes.
      start_seq, content, end_seq = match.captures
      existing_codes = start_seq[2..-2]
      updated_codes = existing_codes.empty? ? color_segment : "#{existing_codes};#{color_segment}"
      "\e[#{updated_codes}m#{content}#{end_seq}"
    else
      # String is not colorized, so we wrap it in new codes.
      "\e[#{color_segment}m#{self}\e[0m"
    end
  end
end
