# frozen_string_literal: true

##
# Converts an RGB color to the nearest matching 8-bit ANSI terminal color code.
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

  # Convenience class method for direct conversion.
  def self.convert(r, g, b)
    min_dist_sq = Float::INFINITY
    alternate_code = -1
    nearest_code = -1
    ANSI_PALETTE.each_with_index do |(ar, ag, ab), code|
      dist_sq = (r - ar)**2 + (g - ag)**2 + (b - ab)**2
      alternate_code ||= code
      nearest_code   ||= code
      next unless dist_sq < min_dist_sq
      alternate_code = nearest_code
      min_dist_sq = dist_sq
      nearest_code = code
    end
    # Alternate color is chosen randomly to simulate dithering.
    rand(2) == 0 ? nearest_code : alternate_code
  end
end

##
# Extend Ruby's String class to add terminal color methods.
class String
  # Matches an ANSI-wrapped string to allow for code chaining.
  ANSI_COLOR_REGEX = /\A(\e\[[\d;]*m)(.*?)(\e\[0m)\z/m

  # Sets the foreground color of the string using an RGB array.
  # @param rgb_array [Array<Integer>] An array of [r, g, b] values (0-255).
  # @return [String] The colorized string.
  def fg(rgb_array)
    apply_color('38;5', rgb_array)
  end

  # Sets the background color of the string using an RGB array.
  # @param rgb_array [Array<Integer>] An array of [r, g, b] values (0-255).
  # @return [String] The colorized string.
  def bg(rgb_array)
    apply_color('48;5', rgb_array)
  end

  private

  # Helper method to apply an ANSI color code to the string.
  # It intelligently handles chained calls by combining ANSI codes.
  def apply_color(type_code, rgb_array)
    ansi_code = AnsiColorConverter.convert(*rgb_array)
    new_color_segment = "#{type_code};#{ansi_code}"

    if (match = match(ANSI_COLOR_REGEX))
      # String is already colorized, so we combine new and existing codes.
      start_seq, content, end_seq = match.captures
      existing_codes = start_seq[2..-2] # Get codes between \e[ and m
      updated_codes = existing_codes&.empty? ? new_color_segment : "#{existing_codes};#{new_color_segment}"
      "\e[#{updated_codes}m#{content}#{end_seq}"
    else
      # String is not colorized, so we wrap it in new codes.
      "\e[#{new_color_segment}m#{self}\e[0m"
    end
  end
end
