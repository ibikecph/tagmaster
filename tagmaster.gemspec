# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'tagmaster/version'

Gem::Specification.new do |spec|
  spec.name          = "tagmaster"
  spec.version       = TagMaster::VERSION
  spec.authors       = ["Emil Tin"]
  spec.email         = ["emil.tin@tmf.kk.dk"]
  spec.summary       = %q{TagMaster RFID reader client.}
  spec.description   = %q{TagMaster RFID reader client for reading tags and working with log data.}
  spec.homepage      = ""
  spec.license       = "Mozilla Public License 2.0"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", '~> 3.4.0', '>= 3.4.0'
end
