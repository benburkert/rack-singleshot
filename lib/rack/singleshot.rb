require 'rack'
require 'http/parser'
require 'uri'

module Rack
  module Handler
    class SingleShot
      CRLF = "\r\n"

      def self.run(app, options = {})
        stdin   = options.fetch(:stdin, $stdin)
        stdout  = options.fetch(:stdout, $stdout)

        stdin.binmode = true  if stdin.respond_to?(:binmode=)
        stdout.binmode = true if stdout.respond_to?(:binmode=)

        new(app, stdin, stdout).run
      end

      def initialize(app, stdin, stdout)
        @app, @stdin, @stdout = app, stdin, stdout
      end

      def run
        request = read_request

        status, headers, body = @app.call(request)

        write_response(status, headers, body)
      ensure
        @stdout.close
        exit
      end


      def read_request
        verb, path, query_string, version, headers, body = parse_request(@stdin)

        env_for(verb, path, query_string, version, headers, body)
      end

      def parse_request(socket, chunksize = 1024)
        finished = false
        body     = StringIO.new('')
        parser   = Http::Parser.new

        body.set_encoding(Encoding::ASCII_8BIT) if body.respond_to?(:set_encoding)

        parser.on_message_complete = lambda { finished = true }
        parser.on_body = lambda {|data| body << data }

        while(chunk = socket.readpartial(chunksize))
          parser << chunk

          break if finished
        end

        return request_parts_from(parser) << body
      rescue EOFError
        return request_parts_from(parser) << body
      end

      def request_parts_from(parser)
        uri = URI.parse(parser.request_url)
        [parser.http_method,
         uri.path,
         uri.query || "",
         parser.http_version.join('.'),
         parse_headers(parser.headers)]
      end

      def parse_headers(raw_headers)
        raw_headers.inject({}) do |h, (key,value)|
          h.update(header_key(key) => value)
        end
      end

      def header_key(key)
        key = key.upcase.gsub('-', '_')

        %w[CONTENT_TYPE CONTENT_LENGTH SERVER_NAME].include?(key) ? key : "HTTP_#{key}"
      end

      def write_response(status, headers, body)
        @stdout.write(['HTTP/1.1', status, Rack::Utils::HTTP_STATUS_CODES[status.to_i]].join(' ') << CRLF)

        headers.each do |key, values|
          values.split("\n").each do |value|
            @stdout.write([key, value].join(": ") << CRLF)
          end
        end

        @stdout.write(CRLF)

        body.each do |chunk|
          @stdout.write(chunk)
        end
      end

      def env_for(verb, path, query_string, version, headers, body)
        env = headers

        scheme = ['yes', 'on', '1'].include?(env['HTTPS']) ? 'https' : 'http'
        host   = env['SERVER_NAME'] || env['HTTP_HOST']

        uri = URI.parse([scheme, '://', host, path].join)

        env.update 'REQUEST_METHOD' => verb
        env.update 'SCRIPT_NAME'    => ''
        env.update 'PATH_INFO'      => uri.path
        env.update 'QUERY_STRING'   => query_string
        env.update 'SERVER_NAME'    => uri.host
        env.update 'SERVER_PORT'    => uri.port.to_s

        env.update 'rack.version'       => Rack::VERSION
        env.update 'rack.url_scheme'    => uri.scheme
        env.update 'rack.input'         => body
        env.update 'rack.errors'        => $stderr
        env.update 'rack.multithread'   => false
        env.update 'rack.multiprocess'  => false
        env.update 'rack.run_once'      => true

        env
      end

    end

    register 'singleshot', 'Rack::Handler::SingleShot'
  end
end
