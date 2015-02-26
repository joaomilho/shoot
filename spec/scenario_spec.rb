require_relative '../lib/shoot'
require 'capybara'

describe 'Shoot::Scenario' do

  describe 'shoot' do
    before do
      allow(Capybara).to receive(:register_driver).with("browser 5.0 os 22.0")
      allow(Capybara).to receive(:current_driver=).with("browser 5.0 os 22.0")
      allow(FileUtils).to receive(:mkdir_p)
      allow(Kernel).to receive(:sleep)

      @scenario = Shoot::Scenario.new({
        'browser' => 'browser',
        'browser_version' => '5.0',
        'os' => 'os',
        'os_version' => '22.0'
      })

      allow(@scenario).to receive(:foo)
      allow(@scenario).to receive(:save_screenshot)
    end

    it 'shoots' do
      @scenario.shoot(:foo)
      expect(@scenario).to have_received(:foo)
      expect(@scenario).to have_received(:save_screenshot)
    end
  end

end
