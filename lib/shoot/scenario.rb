require 'selenium-webdriver'
require 'capybara'
require 'timeout'

require 'selenium/webdriver/remote/http/curb'

module Selenium
  module WebDriver
    module Remote
      class Bridge
        attr_accessor :http_curb
        def http
          unless @http_curb
            @http_curb = Http::Curb.new
            @http_curb.server_url = @http.send(:server_url)
          end
          @http_curb
        end
      end # Bridge
    end # Remote
  end # WebDriver
end # Selenium

class Shoot::Scenario
  URL = sprintf 'http://%s:%s@hub.browserstack.com/wd/hub',
                ENV['BROWSERSTACK_USER'],
                ENV['BROWSERSTACK_KEY']

  include Capybara::DSL

  def initialize(platform=nil)
    if platform
      @platform = platform
      config_capabilities

      Capybara.register_driver platform_name do |app|
        Capybara::Selenium::Driver.new(app,
                                       browser: :remote,
                                       url: URL,
                                       desired_capabilities: @capabilities)
        end
    else
      require 'capybara/poltergeist'

      Capybara.run_server = false
      @platform_name = :poltergeist
    end
    Capybara.default_wait_time = 10
    Capybara.current_driver = platform_name
  end

  def find *args
    Timeout.timeout(10) do
      begin
        super *args
      rescue
        retry
      end
    end
  end

  def run(method)
    @current_method = method
    send(method)
    #Kernel.sleep(1) # Just in case
    shoot(:finish)
    [true, nil]
  rescue => e
    #puts "FAILED #{method}: #{e.inspect}"
    shoot(:failed)
    [false, e]
  end

  def ok
    page.driver.quit
  end

  def platform_name
    @platform_name ||= if @platform['device']
                         @platform['device']
                       else
                         name_items = %w(browser browser_version os os_version)
                         @platform.values_at(*name_items).join(' ')
                       end
  end

  private

  def shoot(label)
    directory = ".screenshots/#{platform_name.to_s.gsub(" ", "_")}/#{self.class.name}/#{@current_method}"
    unless Dir.exist?(directory)
      require 'fileutils'
      FileUtils::mkdir_p directory
    end

    save_screenshot("#{directory}/#{label}.png")
  end

  def config_capabilities # rubocop:disable AbcSize
    @capabilities = Selenium::WebDriver::Remote::Capabilities.new
    @capabilities[:browser] = @platform['browser']
    @capabilities[:browser_version] = @platform['browser_version']
    @capabilities[:os] = @platform['os']
    @capabilities[:os_version] = @platform['os_version']
    @capabilities['browserstack.debug'] = 'true'
    @capabilities[:name] = "Digital Goods - #{@platform}"
    @capabilities[:browserName] = @platform['browser']
    @capabilities[:platform] = @platform['os']
    @capabilities[:device] = @platform['device'] if @platform['device']
  end

end
