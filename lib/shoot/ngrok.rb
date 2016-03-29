require 'childprocess'
require 'forwardable'
require 'securerandom'

module Shoot
  class Ngrok
    extend Forwardable
    def_delegators :@process, :start, :stop, :exited?

    def initialize(options)
      port = options[:port] || 3000
      subdomain_prefix = options[:subdomain_prefix]
      params = ["ngrok", "http", port.to_s, "-log=stdout", "-subdomain=#{subdomain(subdomain_prefix)}"]
      params << "-authtoken=#{options[:auth_token]}" if options[:auth_token]
      @process = ChildProcess.build(*params)

      start
    end

    def subdomain(prefix)
      @subdomain ||= "shoot-#{prefix}-#{Time.now.to_i}-#{SecureRandom.random_number(10**8)}"
    end

    def url
      @url ||= "http://#{subdomain}.ngrok.io"
    end
  end
end
