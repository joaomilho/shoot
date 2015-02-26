require_relative '../lib/shoot/cli'

describe 'Shoot::CLI' do
  subject(:cli) do
    Shoot::CLI.new
  end

  let(:mock_json) do
    [
      {os: "Foo", os_version: "Foo 1", browser: "Foo browser", device: nil, browser_version: "6.0", id: 0, 'active' => false},
      {os: "Bar", os_version: "Bar 2", browser: "Bar browser", device: nil, browser_version: "7.0", id: 1, 'active' => true}
    ]
  end

  before do
    allow(cli).to receive(:json).and_return(mock_json)
  end

  describe 'list' do
    before do
      allow(cli).to receive(:json).and_return(mock_json)
      allow(cli).to receive(:table) {|arg| arg }
    end

    context 'list all' do
      it 'show the json in a table' do
        expect(cli.list).to eq(mock_json)
      end
    end

    context 'list with filter' do
      it 'show the the filtered json in a table' do
        expect(cli.list("Foo browser")).to eq([mock_json[0]])
        expect(cli.list("7.0")).to eq([mock_json[1]])
      end
    end
  end

  describe 'active' do
    before do
      allow(cli).to receive(:table) {|arg| arg }
    end

    it 'displays the active browsers' do
      expect(cli.active).to eq([mock_json[1]])
    end
  end

  describe 'activate' do
    before do
      allow(cli).to receive(:table) {|arg| arg }
      allow(cli).to receive(:save_json)
    end

    it 'activates the browser' do
      expect{ cli.activate(0) }.to change{ mock_json[0]['active'] }.from(false).to(true)
      expect(cli).to have_received(:save_json)
    end
  end

  describe 'deactivate' do
    before do
      allow(cli).to receive(:table) {|arg| arg }
      allow(cli).to receive(:save_json)
    end

    it 'deactivates the browser' do
      expect{ cli.deactivate(1) }.to change{ mock_json[1]['active'] }.from(true).to(false)
      expect(cli).to have_received(:save_json)
    end
  end

  describe 'scenario' do
    before do
      class Foo
        def initialize(config); end
        def method; end
      end

      allow_any_instance_of(Foo).to receive(:shoot)
      expect_any_instance_of(Foo).to receive(:ok)

      allow(cli).to receive(:_active).and_return(["foo"])
      allow(cli).to receive(:require_file)
    end

    it 'runs scenario' do
      cli.scenario('foo.rb')
      expect(cli).to have_received(:require_file)
    end
  end

end
