require 'thor'
require 'benchmark'
require 'highline/import'

module Shoot
  class CLI < Thor
    include UI

    require 'fileutils'
    FileUtils::mkdir_p '.screenshots'
    map %w[--version -v] => :version
    map %w[--interactive -i] => :interactive

    desc 'version, --version, -v', 'Shoot version'
    def version
      puts Shoot::VERSION
    end


    desc 'interactive, --interactive, -i', 'Interactive mode'
    def interactive
      interactive_commands = {
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

      @exit = false
      while ! @exit
        choose do |menu|
          menu.layout = :menu_only
          menu.shell  = true

          interactive_commands.each do |command_name, command_action|
            menu.choice(command_name, desc(command_name)){|_, details| command_action.call(details) }
          end
        end
      end
    end

    desc 'open', 'Opens all screenshots taken'
    def open
      `open #{Dir.glob(".screenshots/**/*.png").join(" ")}`
    end

    desc 'list [FILTER]', 'List all platforms. Optionally passing a filter'
    def list(filter = nil)
      table filter ? Browser.filter(filter) : Browser.all
    end

    desc 'active', 'List active platforms.'
    def active
      table Browser.active
    end

    desc 'scenario PATH', 'Runs the given scenario or all files in a directory on all active platforms'
    def scenario(path)
      scenarios = File.directory?(path) ? Dir.glob("#{path}/*.rb") : [path]

      elapsed_time do
        Browser.active.each do |browser|
          scenarios.each do |scenario|
            run scenario, browser
          end
        end
        print set_color("\nAll tests finished", :blue)
      end
    end

    desc 'test PATH', 'Runs the given scenario or all files in a directory on a local phantomjs'
    def test(path)
      scenarios = File.directory?(path) ? Dir.glob("#{path}/*.rb") : [path]
      elapsed_time do
        scenarios.each{|scenario| run scenario }
        print set_color("\nAll tests finished", :blue)
      end
    end

    desc 'activate IDs', 'Activate platforms, based on IDs'
    def activate(*ids)
      return puts "No ids provided, e.g. 'activate 123'" if ids.empty?
      table Browser.activate(ids)
    end

    desc 'deactivate IDs', 'Deactivate platforms, based on IDs'
    def deactivate(*ids)
      return puts "No ids provided, e.g. 'deactivate 123'" if ids.empty?
      table Browser.deactivate(ids)
    end

    desc 'deactivate_all', 'Deactivate all the platforms'
    def deactivate_all
      Browser.deactivate_all
    end

    desc 'update', 'Update browser list (WARNING: will override active browsers)'
    def update
      Browser.update_json
      list
    end

    no_commands do

      def elapsed_time
        elapsed_time = Benchmark.measure { yield }
        print set_color "  (#{elapsed_time.real.to_i}s)\n", :blue
      end

      def desc(command)
        CLI.commands[command.to_s].description rescue nil
      end

      def run(scenario, browser = nil)
        runner = ScenarioRunner.new(scenario, browser)
        puts set_color runner.platform_name, :white, :bold
        runner.each_method do |method|
          print set_color "  ➥ #{runner.klass}##{method} ... ", :white, :bold
          error = nil

          elapsed_time do
            ok, error = runner.run(method)

            print ok ? set_color("OK", :green) : set_color("FAILED", :red)
          end
          puts set_color "    ⚠ #{error}", :red if error
        end

      end

    end
  end
end
