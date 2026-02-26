RSpec.describe Barf do
  it "has a version number" do
    expect(Barf::VERSION).not_to be nil
  end

  describe ".print" do
    let(:photo_path) { File.expand_path("photo.jpg", __dir__) }

    it "renders an image to stdout without errors" do
      output = capture_output { Barf.print(photo_path) }
      expect(output).not_to be_empty
    end

    it "outputs ANSI color escape codes" do
      output = capture_output { Barf.print(photo_path) }
      expect(output).to match(/\e\[/)
    end

    it "produces deterministic output" do
      first  = capture_output { Barf.print(photo_path) }
      second = capture_output { Barf.print(photo_path) }
      expect(first).to eq(second)
    end

    it "returns nil" do
      result = capture_output { |r| r[:return] = Barf.print(photo_path) }
      expect(result).to be_nil
    end

    private

    # Captures $stdout and returns it as a string.
    # Optionally yields a hash so the caller can capture the return value.
    def capture_output
      result = {}
      output = StringIO.new
      original_stdout = $stdout
      $stdout = output
      yield(result)
      $stdout = original_stdout
      return result[:return] if result.key?(:return)
      output.string
    end
  end
end
