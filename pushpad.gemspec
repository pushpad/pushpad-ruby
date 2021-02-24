Gem::Specification.new do |spec|
  spec.name          = "pushpad"
  spec.version       = '0.12.0'
  spec.authors       = ["Pushpad"]
  spec.email         = ["support@pushpad.xyz"]
  spec.summary       = "Web push notifications for Chrome, Firefox, Opera, Edge and Safari using Pushpad."
  spec.homepage      = "https://pushpad.xyz"
  spec.license       = "MIT"
  spec.files         = `git ls-files`.split("\n")
  spec.test_files    = `git ls-files -- spec/*`.split("\n")
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "webmock"
end
