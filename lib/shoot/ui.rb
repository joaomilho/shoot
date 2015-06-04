module Shoot
  module UI
    TABLE_HEADER = ['ID', 'OS #', 'Browser #', 'Device', 'Emulator']

    def table(browsers)
      table = browsers.map do |browser|
        to_row(browser)
      end.unshift(TABLE_HEADER)
      print_table table, truncate: true
    end

    private

    def to_row(browser)
      [
        set_color(browser.id.to_s, browser.active ? :green : :red),
        "#{browser.os} #{browser.os_version}",
        "#{browser.browser} #{browser.browser_version}",
        browser.device,
        browser.emulator ? 'Yes' : set_color('No', :black)
      ]
    end
  end
end
