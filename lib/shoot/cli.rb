require 'thor'
require 'json'
require 'highline/import'

module Shoot
  class CLI < Thor
    require 'fileutils'
    FileUtils::mkdir_p '.screenshots'
    BROWSERS_PATH = '.screenshots/.browsers.json'
    map %w[--version -v] => :version
    map %w[--interactive -i] => :interactive

    desc 'version, --version, -v', 'Shoot version'
    def version
      puts Shoot::VERSION
    end

    desc 'interactive, --interactive, -i', 'Activate one platform, based on ID or interval'
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

    desc 'list', 'List all platforms. Optionally pass a filter (e.g. browserstack list ie)'
    def list(filter = nil)
      table json.select { |p| p.inspect =~ /#{filter}/i }
    end

    desc 'active', 'List active platforms.'
    def active
      table _active
    end

    desc 'scenario', 'Runs the given scenario on all active platforms or one platform, based on ID'
    def scenario(file, id = nil)
      runners = id ? [json[id.to_i]] : _active
      runners.each {|config| run file, config }
    end

    desc 'test', 'Runs the given scenario or all files in a directory on a local phantomjs'
    def test(path)
      files = File.directory?(path) ? Dir.glob("#{path}/*.rb") : [path]
      files.each{|file| run file }
    end

    desc 'activate', 'Activate one platform, based on ID or interval'
    def activate(from_id, to_id = from_id)
      ids = (from_id.to_i..to_id.to_i).to_a
      ids.each { |id| json[id]['active'] = true }
      save_json
      table json[from_id.to_i - 2, ids.size + 4]
    end

    desc 'deactivate', 'Deactivate one platform, based on ID'
    def deactivate(id)
      json[id.to_i]['active'] = false
      save_json
      table json[id.to_i - 2, 5]
    end

    desc 'deactivate_all', 'Deactivate all the platforms'
    def deactivate_all
      _active.each do |child|
        child['active'] = false
      end
      save_json
    end

    no_commands do
      def open_all_screenshots
        `open #{Dir.glob(".screenshots/**/*.png").join(" ")}`
      end

      def run(file, config=nil)
        klass = get_const_from_file(file)
        instance = klass.new(config)
        puts set_color instance.platform_name, :white, :bold
        klass.instance_methods(false).each do |method|
          print set_color "  ➥ #{klass}##{method} ... ", :white, :bold

          ok, error = instance.run(method)
          if ok
            print set_color "OK\n", :green
          else
            print set_color "FAILED\n", :red
            puts set_color "    ⚠ #{error}", :red
          end
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
        end.unshift(['ID', 'OS #', 'Browser #', 'Device'])
        print_table table, truncate: true
      end

      def to_row(p)
        [
          p['id'].to_s.colorize(p['active'] ? :green : :red),
          "#{p['os']} #{p['os_version']}",
          "#{p['browser']} #{p['browser_version']}",
          p['device']
        ]
      end

      def json
        File.write(BROWSERS_PATH, JSON.dump(fetch_json_and_prepare)) unless File.exist?(BROWSERS_PATH)
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
        JSON.parse(RestClient.get("https://#{ENV['BROWSERSTACK_USER']}:#{ENV['BROWSERSTACK_KEY']}@www.browserstack.com/automate/browsers.json")).tap do |json|
          json.each_with_index do |browser, index|
            browser['id'] = index
          end
        end
      end
    end
  end
end
