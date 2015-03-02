require 'selenium-webdriver'
require 'capybara'

class Shoot::Scenario
  URL = sprintf 'http://%s:%s@hub.browserstack.com/wd/hub',
                ENV['BROWSERSTACK_USER'],
                ENV['BROWSERSTACK_KEY']

  include Capybara::DSL

  def initialize(platform)
    @platform = platform
    config_capabilities

    Capybara.register_driver platform_name do |app|
      Capybara::Selenium::Driver.new(app,
                                     browser: :remote,
                                     url: URL,
                                     desired_capabilities: @capabilities)
    end

    puts "Running #{platform_name}"
    Capybara.current_driver = platform_name
  end

  def shoot(method)
    send(method)
    Kernel.sleep(1) # Just in case
    require 'fileutils'
    FileUtils::mkdir_p '.screenshots'
    save_screenshot(".screenshots/#{method} #{platform_name}.png")
  end

  def ok
    puts 'OK'
    page.driver.quit
  end

  private

  def platform_name
    @platform_name ||= if @platform['device']
                         @platform['device']
                       else
                         name_items = %w(browser browser_version os os_version)
                         @platform.values_at(*name_items).join(' ')
                       end
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
