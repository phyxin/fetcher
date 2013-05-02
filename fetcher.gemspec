# coding: utf-8

Gem::Specification.new do |spec|
  spec.name          = "mail-fetcher"
  spec.version       = "1.0.0"
  spec.authors       = ["Dan Weinand", "Luke Francl"]
  spec.description   = %q{download email from POP3 or IMAP and do stuff with it.}
  spec.summary       = %q{download email from POP3 or IMAP and do stuff with it.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
