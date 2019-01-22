
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "barf/version"

Gem::Specification.new do |spec|
  spec.name          = "barf"
  spec.version       = Barf::VERSION
  spec.authors       = ["Jacob Duffy"]
  spec.email         = ["duffy.jp@gmail.com"]

  spec.summary       = "Output images in terminal"
  spec.homepage      = "https://github.com/duffyjp/barf"
  spec.license       = "MIT"
  
  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Read and process images
  spec.add_dependency "mini_magick", '>= 3.6.0'
  spec.add_dependency "parallel"

  # Easier terminal color setting
  spec.add_dependency "tco"

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
