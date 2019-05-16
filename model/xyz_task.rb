# encoding:utf-8

module XYZ
  module Task
    @data = {}

    module_function

    def add(name, &block)
      @data[name] = { proc: block, name: name }
    end

    def run(name, *args)
      if @data.include?(name)
        return @data[name][:proc].call(*args)
      end
    end

    attr_reader :data
  end
end
