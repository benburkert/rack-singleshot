$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'rack/singleshot'
require 'sinatra'

RSpec.configure do |config|
  config.color = true
end
