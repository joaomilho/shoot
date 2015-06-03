module Shoot
  class NgrokPow < Ngrok
    def initialize(server)
      `ln -s ~/.pow/#{server} ~/.pow/#{subdomain}`
      @process = ChildProcess.build("ngrok", "-log=stdout", "-subdomain=#{subdomain}", "#{subdomain}.dev:80")
      start

      at_exit do
        `rm ~/.pow/#{subdomain}`
      end
    end
  end
end
