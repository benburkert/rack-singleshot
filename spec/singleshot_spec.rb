require 'spec_helper'

describe Rack::Handler::SingleShot do
  before(:all) do
    @stdin, @in   = IO.pipe
    @out, @stdout = IO.pipe

    @app = Rack::Lint.new(lambda {|env| [200, {'Content-Type' => 'text/plain'}, []] })
    @server = Rack::Handler::SingleShot.new(@app, @stdin, @stdout)
  end

  it 'can handle a simple request' do
    @in << <<-REQUEST.gsub("\n", "\r\n")
GET / HTTP/1.1
Server-Name: localhost

REQUEST

    @server.run

    @out.read.should == <<-RESPONSE.gsub("\n", "\r\n")
HTTP/1.1 200 OK
Content-Type: text/plain

RESPONSE
  end
end
