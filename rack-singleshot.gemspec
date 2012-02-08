dir = File.dirname(__FILE__)
$:.unshift dir + '/lib'

require 'rack/singleshot'

Gem::Specification.new do |s|
  s.name        = 'rack-singleshot'
  s.version     = '0.0.0'
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Ben Burkert']
  s.email       = ['ben@benburkert.com']
  s.homepage    = 'http://github.com/benburkert/rack-singleshot'
  s.summary     = "A single-shot rack handler."
  s.description = <<-SUMMARY
Handles a single request to/from STDIN/STDOUT. Exits when the response
has finished. Sutable for running via inetd.
SUMMARY

  s.add_dependency 'rack'

  s.add_development_dependency 'rspec'
  s.add_development_dependency 'rake'

  s.files         = Dir["#{dir}/lib/**/*.rb"]
  s.require_paths = ["lib"]

  s.test_files    = Dir["#{dir}/spec/**/*.rb"]
end

