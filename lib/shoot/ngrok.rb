require 'childprocess'
require 'forwardable'
require 'securerandom'

module Shoot
  class Ngrok
    extend Forwardable
    def_delegators :@process, :start, :stop, :exited?

    def initialize(port = 3000)
      @process = ChildProcess.build("ngrok", "-log=stdout", "-subdomain=#{subdomain}", port.to_s)
      start
    end

    def subdomain
      @subdomain ||= "shoot-#{Time.now.to_i}-#{SecureRandom.random_number(10**8)}"
    end

    def url
      @url ||= "http://#{subdomain}.ngrok.com"
    end
  end
end
