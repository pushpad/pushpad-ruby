Gem::Specification.new do |spec|
  spec.name          = "pushpad"
  spec.version       = '0.5.1'
  spec.authors       = ["Pushpad"]
  spec.email         = ["support@pushpad.xyz"]
  spec.summary       = "Web push notifications for Chrome, Firefox and Safari using Pushpad."
  spec.homepage      = "https://pushpad.xyz"
  spec.license       = "MIT"
  spec.files         = ["Gemfile", "LICENSE.txt", "README.md", "lib/pushpad.rb"]
  spec.test_files    = ["spec/spec_helper.rb", "spec/pushpad_spec.rb"]
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "webmock"
end
