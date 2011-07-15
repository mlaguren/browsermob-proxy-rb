require 'childprocess'
require 'socket'

module BrowserMob
  module Proxy

    class Server
      attr_reader :port

      def initialize(path, opts = {})
        unless File.exist?(path)
          raise Errno::ENOENT, path
        end

        unless File.executable?(path)
          raise Errno::EACCES, "not executable: #{path}"
        end

        @path = path
        @port = Integer(opts[:port] || 8080)

        @process = ChildProcess.new(path, "--port", port.to_s)
        @process.io.inherit! if opts[:log]
      end

      def start
        @process.start
        sleep 0.1 until listening?

        self
      end

      def url
        "http://localhost:#{port}"
      end

      def create_proxy
        Client.from url
      end

      def stop
        return unless @process.alive?

        begin
          @process.poll_for_exit(5)
        rescue ChildProcess::TimeoutError
          @process.stop
        end
      rescue Errno::ECHILD
        # already dead
      ensure
        @process = nil
      end

      private


      def listening?
        TCPSocket.new("localhost", port).close
        true
      rescue
        false
      end
    end # Server

  end # Proxy
end # BrowserMob