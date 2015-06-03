require 'thor'
require 'json'
require 'highline/import'

module Shoot
  class CLI < Thor

    EMULATORS_UNAVAILABLE_ON_THE_API = ["iPad 3rd", "iPad 3rd (6.0)", "iPad Mini", "iPad 4th", "iPhone 4S", "iPhone 4S (6.0)", "iPhone 5", "iPhone 5S"].map do |device|
      {
        browser: "iPhone",
        os: "MAC",
        device: device,
        emulator: true
      }
    end

    require 'fileutils'
    FileUtils::mkdir_p '.screenshots'
    BROWSERS_PATH = '.screenshots/.browsers.json'
    map %w[--version -v] => :version
    map %w[--interactive -i] => :interactive

    desc 'version, --version, -v', 'Shoot version'
    def version
      puts Shoot::VERSION
    end

    desc 'interactive, --interactive, -i', 'Interactive mode'
    def interactive
      @exit = false

      available_commands = {
        active:         ->(_)     { active },
        activate:       ->(params){ activate(*params.split(" ")) },
        deactivate:     ->(params){ deactivate(*params.split(" ")) },
        deactivate_all: ->(_)     { deactivate_all },
        list:           ->(params){ list(params) },
        open:           ->(_)     { open },
        test:           ->(params){ test(params) },
        scenario:       ->(params){ scenario(params) },
        update:         ->(_)     { update },
        exit:           ->(_)     { @exit = true }
      }

      while ! @exit
        choose do |menu|
          menu.layout = :menu_only
          menu.shell  = true

          available_commands.each do |command_name, command_action|
            menu.choice(command_name, desc(command_name)){|_, details| command_action.call(details) }
          end
        end
      end
    end

    desc 'open', 'Opens all screenshots taken'
    def open
      open_all_screenshots
    end

    desc 'list [FILTER]', 'List all platforms. Optionally passing a filter'
    def list(filter = nil)
      table json.select { |p| p.inspect =~ /#{filter}/i }
    end

    desc 'active', 'List active platforms.'
    def active
      table _active
    end

    desc 'scenario PATH', 'Runs the given scenario or all files in a directory on all active platforms'
    def scenario(path)
      files = File.directory?(path) ? Dir.glob("#{path}/*.rb") : [path]

      elapsed_time do
        _active.each do |config|
          files.each do |file|
            run file, config
          end
        end
        print set_color("\nAll tests finished", :blue)
      end
    end

    desc 'test PATH', 'Runs the given scenario or all files in a directory on a local phantomjs'
    def test(path)
      files = File.directory?(path) ? Dir.glob("#{path}/*.rb") : [path]
      elapsed_time do
        files.each{|file| run file, nil }
        print set_color("\nAll tests finished", :blue)
      end
    end

    desc 'activate IDs', 'Activate platforms, based on IDs'
    def activate(*ids)
      _activate(ids)
    end

    desc 'deactivate IDs', 'Deactivate platforms, based on IDs'
    def deactivate(*ids)
      _deactivate(ids)
    end

    desc 'deactivate_all', 'Deactivate all the platforms'
    def deactivate_all
      _active.each do |child|
        child['active'] = false
      end
      save_json
    end

    desc 'update', 'Update browser list (WARNING: will override active browsers)'
    def update
      update_json
      list
    end

    no_commands do
      def elapsed_time
        require 'benchmark'

        elapsed_time = Benchmark.measure do
          yield
        end
        print set_color "  (#{elapsed_time.real.to_i}s)\n", :blue
      end

      def desc(command)
        CLI.commands[command.to_s].description rescue nil
      end

      def _activate(ids)
        return puts "No ids provided, e.g. 'activate 123'" if ids.empty?
        ids.map!(&:to_i)
        ids.each { |id| json[id]['active'] = true }
        save_json
        table json.select{|item| ids.include?(item['id']) }
      end

      def _deactivate(ids)
        return puts "No ids provided, e.g. 'deactivate 123'" if ids.empty?
        ids.map!(&:to_i)
        ids.each { |id| json[id]['active'] = false }
        save_json
        table json.select{|item| ids.include?(item['id']) }
      end

      def open_all_screenshots
        `open #{Dir.glob(".screenshots/**/*.png").join(" ")}`
      end

      def run(file, config = nil)
        klass = get_const_from_file(file)
        instance = klass.new(config)
        puts set_color instance.platform_name, :white, :bold
        klass.instance_methods(false).each do |method|
          print set_color "  ➥ #{klass}##{method} ... ", :white, :bold
          error = nil

          elapsed_time do
            ok, error = instance.run(method)

            print ok ? set_color("OK", :green) : set_color("FAILED", :red)
          end
          puts set_color "    ⚠ #{error}", :red if error
        end
        instance.ok
      end

      def require_file(file)
        require Dir.pwd + '/' + file
      end

      def constantize_file_name(file)
        klass_name = File.basename(file, '.rb').split('_').map(&:capitalize).join
        Kernel.const_get(klass_name)
      end

      def get_const_from_file(file)
        require_file(file)
        constantize_file_name(file)
      end

      def table(browsers)
        table = browsers.map do |p|
          to_row(p)
        end.unshift(['ID', 'OS #', 'Browser #', 'Device', 'Emulator'])
        print_table table, truncate: true
      end

      def to_row(p)
        [
          set_color(p['id'].to_s, p['active'] ? :green : :red),
          "#{p['os']} #{p['os_version']}",
          "#{p['browser']} #{p['browser_version']}",
          p['device'],
          p['emulator'] ? 'Yes' : set_color('No', :black)
        ]
      end

      def update_json
        File.write(BROWSERS_PATH, JSON.dump(fetch_json_and_prepare))
      end

      def json
        update_json unless File.exist?(BROWSERS_PATH)
        @json ||= JSON.parse(File.read(BROWSERS_PATH))
      end

      def _active
        @active ||= json.select { |p| p['active'] }
      end

      def save_json
        File.write(BROWSERS_PATH, JSON.pretty_generate(json))
      end

      def fetch_json_and_prepare
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
end
