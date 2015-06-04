require 'json'

class Hash
  def symbolize_keys
    self.keys.each do |key|
      self[key.to_sym] = self.delete(key)
    end
    self
  end
end


module Shoot
  class Browser
    BROWSERS_PATH = '.screenshots/.browsers.json'
    EMULATORS_UNAVAILABLE_ON_THE_API = ["iPad 3rd", "iPad 3rd (6.0)", "iPad Mini", "iPad 4th", "iPhone 4S", "iPhone 4S (6.0)", "iPhone 5", "iPhone 5S"].map do |device|
      {
        browser: "iPhone",
        os: "MAC",
        device: device,
        emulator: true
      }
    end

    def self.all
      @@all ||= fetch_json.map { |browser| Browser.new(browser.symbolize_keys) }
    end

    def self.activate(ids)
      update(select_by_ids(ids), :activate)
    end

    def self.deactivate(ids)
      update(select_by_ids(ids), :deactivate)
    end

    def self.deactivate_all
      update(active, :deactivate)
    end

    def self.active
      all.select(&:active)
    end

    def self.update_json
      File.write(BROWSERS_PATH, JSON.dump(fetch_and_prepare))
    end

    def self.filter(filter)
      all.select { |browser| browser.inspect =~ /#{filter}/i }
    end

    def self.select_by_ids(ids)
      ids = ids.map(&:to_i)
      all.select { |browser| ids.include?(browser.id) }
    end

    def self.save
      File.write(BROWSERS_PATH, JSON.pretty_generate(all.map(&:to_h)))
    end

    attr_reader :id, :os, :os_version, :browser, :device, :browser_version, :active, :emulator
    def initialize(id:, os:, browser:, device:, os_version: nil, browser_version: nil, active: false, emulator: false)
      @id = id
      @os = os
      @os_version = os_version
      @browser = browser
      @device = device
      @browser_version = browser_version
      @active = active
      @emulator = emulator
    end

    def activate
      @active = true
    end

    def deactivate
      @active = false
    end

    def to_h
      {
        id: id,
        os: os,
        os_version: os_version,
        browser: browser,
        device: device,
        browser_version: browser_version,
        active: active,
        emulator: emulator
      }
    end

    private

    def self.update(browsers, action)
      browsers.map(&action)
      save
      browsers
    end

    def self.fetch_json
      update_json unless File.exist?(BROWSERS_PATH)
      JSON.parse(File.read(BROWSERS_PATH))
    end

    def self.fetch_and_prepare
      require 'rest_client'
      json = JSON.parse(RestClient.get("https://#{ENV['BROWSERSTACK_USER']}:#{ENV['BROWSERSTACK_KEY']}@www.browserstack.com/automate/browsers.json"))
      json += EMULATORS_UNAVAILABLE_ON_THE_API
      json.each_with_index do |browser, index|
        browser['id'] = index
      end
      json
    end

  end
end
