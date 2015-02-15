require 'thor'
require 'json'
require 'colorize'

module Shoot
  class CLI < Thor
    BROWSERS_PATH = '.browsers.json'

    desc 'list', 'List all platforms. Optionally pass a filter (e.g. browserstack list ie)'
    def list(filter = nil)
      table json.select { |p| p.inspect =~ /#{filter}/i }
    end

    desc 'active', 'List active platforms.'
    def active
      table _active
    end

    desc 'scenario', 'Runs the given scenario on all active platforms or one platform, based on ID'
    def scenario(file, id = nil, test = 'all')
      require Dir.pwd + '/' + file
      klass_name = File.basename(file, '.rb').split('_').map(&:capitalize).join
      klass = Kernel.const_get(klass_name)

      runners = id ? [json[id.to_i]] : _active
      runners.each do |config|
        instance = klass.new(config)
        klass.instance_methods(false).each do |method|
          instance.shoot(method)
        end
        instance.ok
      end
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

    no_commands do
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
        File.write(BROWSERS_PATH, JSON.dump(json))
      end

      def fetch_json_and_prepare
        require 'rest_client'
        JSON.parse(RestClient.get("https://juanlulkin1:NDswkopCqKPmA9wWAQws@www.browserstack.com/automate/browsers.json")).tap do |json|
          json.each_with_index do |browser, index|
            browser['id'] = index
          end
        end
      end
    end
  end
end
