require 'rake'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new do |t|
    t.rspec_opts = %w[ -c -f documentation -r ./spec/spec_helper.rb ]
      t.pattern = 'spec/**/*_spec.rb'
end

task :default  => :spec
