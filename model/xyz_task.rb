# encoding:utf-8

module XYZ
  module Task
    @data = {}

    module_function

    def add(name, &block)
      @data[name] = { proc: block, name: name, pid: 0 }
    end

    def run(name, *args)
      if @data.include?(name)
        return @data[name][:proc].call(*args)
      end
    end

    def run_bg(name, *args)
      if @data.include?(name)
        pid = @data[name][:proc].call(*args)
        @data[name][:pid] = pid
      end
    end

    def kill_bg(name)
      pid = @data[name][:pid]
      Process.kill(9, pid)
    end

    attr_reader :data
  end
end
