require_relative '../lib/shoot'
require 'capybara'

describe 'Shoot::Scenario' do

  describe 'run' do
    before do
      allow(Capybara).to receive(:register_driver).with("browser 5.0 os 22.0")
      allow(Capybara).to receive(:current_driver=).with("browser 5.0 os 22.0")
      allow(FileUtils).to receive(:mkdir_p)

      @scenario = Shoot::Scenario.new(OpenStruct.new({
        'browser' => 'browser',
        'browser_version' => '5.0',
        'os' => 'os',
        'os_version' => '22.0'
      }))

      allow(@scenario).to receive(:foo)
      allow(@scenario).to receive(:save_screenshot)
    end

    it 'runs' do
      @scenario.run(:foo)
      expect(@scenario).to have_received(:foo)
      expect(@scenario).to have_received(:save_screenshot)
    end
  end

end
