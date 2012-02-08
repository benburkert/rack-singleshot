require 'rack'

module Rack
  module Handler
    class SingleShot
      CRLF = "\r\n"

      def self.run(app, options = {})
        stdin   = options.fetch(:stdin, $stdin)
        stdout  = options.fetch(:stdout, $stdout)
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
        $stdout.close
      end

      def read_request
        verb, path, version = @stdin.gets(CRLF).split(' ')

        headers = parse_headers(@stdin.gets(CRLF * 2))

        if length = request_body_length(verb, headers)
          body = StringIO.new(@stdin.read(length))
        else
          body = StringIO.new('')
        end

        env_for(verb, path, version, headers, body)
      end

      def write_response(status, headers, body)
        $stdout.write(['HTTP/1.1', status, Rack::Utils::HTTP_STATUS_CODES[status.to_i]].join(' ') << CRLF)

        headers.each do |key, values|
          values.split("\n").each do |value|
            $stdout.write([key, value].join(": ") << CRLF)
          end
        end

        $stdout.write(CRLF)

        body.each do |chunk|
          $stdout.write(chunk)
        end
      end

      def parse_headers(raw_headers)
        raw_headers.split(CRLF).inject({}) do |h, pair|
          key, value = pair.split(": ")
          h.update(header_key(key) => value)
        end
      end

      def request_body_length(verb, headers)
        return if %w[ POST PUT ].include?(verb.upcase)

        if length = headers['CONTENT_LENGTH']
          length.to_i
        end
      end

      def env_for(verb, path, version, headers, body)
        env = headers

        uri = URI.parse(headers['SERVER_NAME']) + path

        env.update 'REQUEST_METHOD' => verb
        env.update 'SCRIPT_NAME'    => File.dirname(uri.path)
        env.update 'PATH_INFO'      => uri.path
        env.update 'QUERY_STRING'   => uri.query || ''
        env.update 'SERVER_NAME'    => uri.host
        env.update 'SERVER_PORT'    => uri.port

        env.update 'rack.version'       => Rack::VERSION
        env.update 'rack.url_scheme'    => uri.scheme
        env.update 'rack.input'         => body
        env.update 'rack.errors'        => $stderr
        env.update 'rack.multithread'   => false
        env.update 'rack.multiprocess'  => false

        env
      end

      def header_key(key)
        formatted_key = key.upcase.gsub('-', '_')
        case key
        when %w[CONTENT_TYPE CONTENT_LENGTH SERVER_NAME] then key
        else "HTTP_#{key}"
        end
      end
    end

    register :singleshot, SingleShot
  end
end
