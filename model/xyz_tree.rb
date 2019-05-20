# encoding:utf-8

module XYZ
  class Tree
    # -- constants -- #
    Codes = {}
    Ends = []
    Code = Struct.new(:id, :name, :in, :out)

    # -- class methods -- #
    class << self
      def refresh_database
        Codes.clear
        Ends.clear
        Codes[0] = Code.new(0, "__END__", [], [])
        Ends << 0
        DB_Code.where(enable: true).each do |code|
          input = JSON.parse(code[:input])
          output = JSON.parse(code[:output])
          c = Code.new(code[:id], code[:name], input, output)
          Codes[c.id] = c
          if input.empty?
            Ends << c.id
          end
        end
      end
    end

    # -- instance methods -- #
    attr_reader :data
    attr_reader :cid

    def initialize(cid)
      @data = create_node(cid)
      @cid = cid
      @nodes = []
    end

    def create_node(cid)
      { __cid__: cid, __end__: Ends.include?(cid) }
    end

    def select_inputs(input)
      ary = [0]
      Codes.each_pair do |id, code|
        if code.out.include?(input)
          ary << id
        end
      end
      ary
    end

    def ready?
      self.question.empty?
    end

    def iteration_data(data_hash = self.data, &block)
      if !data_hash[:__end__]
        cid = data_hash[:__cid__]
        code = Codes[cid]
        code.in.each do |input|
          if data_hash[input].is_a?(Hash)
            # -- recursive -- #
            iteration_data(data_hash[input], &block)
            # -- recursive -- #
          else
            yield input, data_hash
          end
        end
      end
    end

    # use this when ready
    def iteration_hash(data_hash = self.data, &block)
      yield data_hash
      cid = data_hash[:__cid__]
      code = Codes[cid]
      code.in.each do |input|
        next if !data_hash[input].is_a?(Hash)
        # -- recursive -- #
        iteration_hash(data_hash[input], &block)
        # -- recursive -- #
      end
    end

    def expand!
      iteration_data { |i, data|
        if data[i].nil?
          data[i] = select_inputs(i)
        end
      }
    end

    def qkey(cid, input)
      cid.to_s + "/" + input
    end

    def question
      q = {}
      iteration_data { |i, data|
        if data[i].is_a?(Array)
          key = qkey(data[:__cid__], i)
          q.update(key => data[i])
        end
      }
      q
    end

    def update(answer)
      # not an answer of question?
      q = self.question
      answer.each_pair { |key, value|
        if !q[key] || !q[key].include?(value)
          answer.delete(key)
        end
      }
      # update data
      iteration_data { |i, data|
        if data[i].is_a?(Array)
          key = qkey(data[:__cid__], i)
          a = answer[key]
          if a
            data[i] = create_node(a)
          end
        end
      }
    end

    def remove_node(cid)
      iteration_hash { |data|
        _cid = data[:__cid__]
        code = Codes[_cid]
        code.in.each do |input|
          next if !data[input].is_a?(Hash)
          next if data[input][:__cid__] != cid
          data.delete(input)
        end
      }
    end

    def nodes
      ary = []
      iteration_hash { |data|
        ary << data[:__cid__]
      }
      # ---------------------------------------------------------------------
      # 下面一行代码将按照执行的顺序输出所有的任务ID，原因如下：
      # 在 iteration_hash 中，会递归的从上级往下级调用各个 code 对应的 hash
      # 这使得在 ary 中，父任务的 ID 一定先于它的任一子任务的 ID
      # 在不考虑重复的情况下，只需要从尾部开始顺次执行即可安全的完成全部任务
      # 因为当执行某个父任务的时候，它的全部子任务都已经完成了
      # uniq 方法会保留第一个遇到的项，所以要先 reverse 后再 uniq 即可
      # ---------------------------------------------------------------------
      # Next line after this comments will output the ordered task ids.
      # In the <iteration_hash>, all code-hashes are calling by their level.
      # Which means when a task's id was added into <ary>, all its childs
      # must be in the <ary>. If we ignore repeats, running <ary> from tail
      # to head is a safe plan to run all tasks. Since Array#uniq keeps first
      # repeat values in array, just let <ary> first take reverse then uniq.
      ary.reverse.uniq
    end

    def next_nodes(finish_nodes = [])
      raise if !ready?

      if finish_nodes.include?(@cid)
        return []
      end
      # ---------------------------------------------------------------------
      # 提取出不包含 finish_nodes 中任意一个元素的结构，ary 中是 [cid, childs]
      # ---------------------------------------------------------------------
      ary = []
      iteration_hash { |data|
        _cid = data[:__cid__]
        code = Codes[_cid]
        childs = code.in.collect { |input| data[input][:__cid__] }
        next if finish_nodes.include?(_cid)
        ary << [_cid, childs - finish_nodes]
      }
      # ---------------------------------------------------------------------
      # 找到所有可以立即计算的内容，但是要从头部开始找
      # 首先选择第一个元素 @cid，标记上
      # 对于每一个被标记的元素 cid，查看其 childs
      # 如果 childs 为空，则此 cid 是可以立即计算的，添加到 ret 里
      # 如果 childs 不为空，则标记其所有的 childs
      # 由于 cid 已经验证过了，解除对 cid 的标记
      # ---------------------------------------------------------------------
      ret = []
      marker = [@cid]
      while !marker.empty?
        _marker = []
        for m in marker
          as = ary.select { |_cid, childs| _cid == m }
          cs = []
          as.each { |_cid, childs| cs.concat(childs) }
          if cs.empty?
            ret << m
          else
            _marker.concat(cs)
          end
        end
        marker = _marker.uniq
      end
      return ret
    end
  end

  # -- user -- #
  class User
    def task_trees
      prefix = "task_tree/"
      getdata_by(prefix)
    end

    def task_tree_insert(tname, cid)
      prefix = "task_tree/"
      tree = Tree.new(cid)
      tree.expand!
      save_data(prefix + tname, tree)
    end

    def task_tree_update(tname, answer_hash)
      prefix = "task_tree/"
      tree = load_data(prefix + tname)
      return if !tree
      if answer_hash.empty?
        # puts tree.nodes
      else
        tree.expand!
        tree.update(answer_hash)
        tree.expand!
        save_data(prefix + tname, tree)
      end
    end

    def task_tree_delete(tname)
      prefix = "task_tree/"
      save_data(prefix + tname, nil)
    end

    def task_tree_remove_node(tname, cid)
      prefix = "task_tree/"
      tree = load_data(prefix + tname)
      return if !tree
      tree.remove_node(cid)
      tree.expand!
      save_data(prefix + tname, tree)
    end
  end
end
