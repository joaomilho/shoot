# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "shoot/version"

Gem::Specification.new do |spec|
  spec.name          = "shoot"
  spec.version       = Shoot::VERSION
  spec.authors       = ["Juan Lulkin"]
  spec.email         = ["juan.lulkin@klarna.com"]
  spec.summary       = %q{A helper to take shots on BrowserStack}
  spec.description   = %q{A helper to take shots on BrowserStack. Run the shoot binary for more info.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"

  spec.add_dependency "selenium-webdriver", "~> 2.44"
  spec.add_dependency "capybara", "~> 2.4"
  spec.add_dependency "thor", "~> 0.19"
  spec.add_dependency "colorize", "~> 0.7"
  spec.add_dependency "rest_client"
end
