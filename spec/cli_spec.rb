require_relative '../lib/shoot'

describe 'Shoot::CLI' do
  subject(:cli) do
    Shoot::CLI.new
  end

  let(:mock_json) do
    [
      {id: 0, os: "Foo", os_version: "Foo 1", browser: "Foo browser", device: nil, browser_version: "6.0", active: false, emulator: false},
      {id: 1, os: "Bar", os_version: "Bar 2", browser: "Bar browser", device: nil, browser_version: "7.0", active: true, emulator: false}
    ]
  end

  before do
    allow(Shoot::Browser).to receive(:fetch_json).and_return(mock_json)
    allow(cli).to receive(:table) {|arg| arg.map(&:to_h) }
  end

  describe 'list' do
    before do
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
    it 'displays the active browsers' do
      expect(cli.active).to eq([mock_json[1]])
    end
  end

  describe 'activate' do
    before do
      allow(cli).to receive(:table) {|arg| arg }
      allow(Shoot::Browser).to receive(:save)
    end

    it 'activates the browser' do
      expect{ cli.activate(0) }.to change{ Shoot::Browser.all[0].active }.from(false).to(true)
      expect(Shoot::Browser).to have_received(:save)
    end
  end

  describe 'deactivate' do
    before do
      allow(cli).to receive(:table) {|arg| arg }
      allow(Shoot::Browser).to receive(:save)
    end

    it 'deactivates the browser' do
      Shoot::Browser.all[1].activate
      expect{ cli.deactivate(1) }.to change{ Shoot::Browser.all[1].active }.from(true).to(false)
      expect(Shoot::Browser).to have_received(:save)
    end
  end

  describe 'deactivate_all' do
    before do
      allow(cli).to receive(:table) {|arg| arg }
      allow(Shoot::Browser).to receive(:save)
    end

    it 'deactivates the browser' do
      Shoot::Browser.all[1].activate
      expect{ cli.deactivate_all }.to change{ Shoot::Browser.all[1].active }.from(true).to(false)
      expect(Shoot::Browser).to have_received(:save)
    end
  end

  describe 'scenario' do
    before do
      allow(Shoot::Browser).to receive(:active).and_return(["foo"])
      allow(cli).to receive(:run)
    end

    it 'runs scenario' do
      cli.scenario('foo.rb')
      expect(cli).to have_received(:run).with("foo.rb", "foo")
    end

  end

  describe 'test' do
    describe 'file' do
      before do
        allow(cli).to receive(:run)
      end

      it 'runs scenario' do
        cli.test('foo.rb')
        expect(cli).to have_received(:run).with("foo.rb")
      end
    end

    describe 'directory' do
      before do
        allow(File).to receive(:directory?).with('foo').and_return(true)
        allow(Dir).to receive(:glob).with('foo/*.rb').and_return(["foo/bar.rb", "foo/baz.rb"])
        allow(cli).to receive(:run)
      end

      it 'runs scenario' do
        cli.test('foo')
        expect(cli).to have_received(:run).with("foo/bar.rb")
        expect(cli).to have_received(:run).with("foo/baz.rb")
      end
    end
  end

  describe 'run' do
    before do
      class Foo
        def initialize(config); end
        def method; end
      end
      allow_any_instance_of(Foo).to receive(:run).and_return([true, ""])
      allow_any_instance_of(Foo).to receive(:platform_name)
      expect_any_instance_of(Foo).to receive(:quit)

      allow_any_instance_of(Shoot::ScenarioRunner).to receive(:get_const_from_file).with("foo.rb").and_return(Foo)
    end

    it 'runs scenario' do
      cli.run('foo.rb', {foo: :bar})
    end
  end

end
