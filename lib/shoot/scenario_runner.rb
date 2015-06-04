module Shoot
  class ScenarioRunner
    attr_reader :klass
    def initialize(scenario, browser = nil)
      @klass = get_const_from_file(scenario)
      @instance = @klass.new(browser)
    end

    def platform_name
      @instance.platform_name
    end

    def each_method
      @klass.instance_methods(false).each do |method|
        yield(method)
      end
      @instance.quit
    end

    def run(method)
      @instance.run(method)
    end

    private

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
  end
end
