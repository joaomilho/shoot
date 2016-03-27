require 'childprocess'
require 'forwardable'
require 'securerandom'

module Shoot
  class Ngrok
    extend Forwardable
    def_delegators :@process, :start, :stop, :exited?

    def initialize(port = 3000, auth_token: nil)
      params = ["ngrok", "http", port.to_s, "-log=stdout", "-subdomain=#{subdomain}"]
      params << "-authtoken=#{auth_token}" if auth_token
      @process = ChildProcess.build(*params)

      start
    end

    def subdomain
      @subdomain ||= "shoot-#{Time.now.to_i}-#{SecureRandom.random_number(10**8)}"
    end

    def url
      @url ||= "http://#{subdomain}.ngrok.io"
    end
  end
end
