require 'selenium-webdriver'
require 'capybara'
require 'timeout'

class Shoot::Scenario

  include Capybara::DSL

  def self.url
    raise "I guess you forgot your browserstack credetials. Take a look at the docs." unless ENV['BROWSERSTACK_USER'] and ENV['BROWSERSTACK_KEY']

    @@url ||= sprintf 'http://%s:%s@hub.browserstack.com/wd/hub',
      ENV['BROWSERSTACK_USER'],
      ENV['BROWSERSTACK_KEY']
  end

  def initialize(platform=nil)
    if platform
      @platform = platform
      config_capabilities

      Capybara.register_driver platform_name do |app|
        Capybara::Selenium::Driver.new(app,
                                       browser: :remote,
                                       url: Shoot::Scenario.url,
                                       desired_capabilities: @capabilities)
        end
    else
      require 'capybara/poltergeist'

      options = {
         :js_errors => false,
         :phantomjs_options => ["--web-security=false"]
      }

      Capybara.register_driver :poltergeist do |app|
        Capybara::Poltergeist::Driver.new(app, options)
      end

      Capybara.run_server = false
      @platform_name = :poltergeist
    end
    Capybara.default_wait_time = 10
    Capybara.current_driver = platform_name
  end

  def run(method)
    @current_method = method
    send(method)
    shoot(:finish)
    [true, nil]
  rescue => e
    File.write("#{directory}/backtrace.txt", e.backtrace.join("\n"))
    shoot(:failed)
    [false, e]
  end

  def quit
    page.driver.quit
  end

  def platform_name
    @platform_name ||= if @platform.device
                         @platform.device
                       else
                         [
                           @platform.browser,
                           @platform.browser_version,
                           @platform.os,
                           @platform.os_version
                         ].join(' ')
                       end
  end

  protected

  # In Selenium the enter key is :return
  # and on poltergeits it is :Enter
  def enter_key
    remote? ? :return : :Enter
  end

  def remote?
    @platform_name != :poltergeist
  end

  def send_enter(selector)
    find(selector).native.send_key(enter_key)
  end

  private

  def directory
    ".screenshots/#{platform_name.to_s.gsub(" ", "_")}/#{self.class.name}/#{@current_method}".tap do |dir|
      unless Dir.exist?(dir)
        require 'fileutils'
        FileUtils::mkdir_p dir
      end
    end
  end

  def shoot(label)
    save_screenshot("#{directory}/#{label}.png", full: true)
  rescue => e
    File.write("#{directory}/#{label}.error.txt", %(#{e.inspect}\n\n#{e.backtrace.join("\n")}))
  end

  def config_capabilities # rubocop:disable AbcSize
    @capabilities = Selenium::WebDriver::Remote::Capabilities.new
    @capabilities[:browser] = @platform.browser
    @capabilities[:browser_version] = @platform.browser_version
    @capabilities[:os] = @platform.os
    @capabilities[:os_version] = @platform.os_version
    @capabilities['browserstack.debug'] = 'true'
    @capabilities[:name] = "Digital Goods - #{@platform.to_h}"
    @capabilities[:browserName] = @platform.browser
    @capabilities[:platform] = @platform.os
    @capabilities[:device] = @platform.device if @platform.device
    @capabilities[:emulator] = @platform.emulator
    @capabilities[:rotatable] = true
  end

end
