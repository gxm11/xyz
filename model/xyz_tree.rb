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

    def initialize(cid)
      @data = create_node(cid)
    end

    def create_node(cid)
      { __cid__: cid, __end__: Ends.include?(cid) }
    end

    def select_inputs(input)
      ary = []
      Codes.each_pair do |id, code|
        if code.out.include?(input)
          ary << id
        end
      end
      ary
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

    def expand!
      iteration_data { |i, data|
        if data[i].nil?
          data[i] = select_inputs(i)
        end
      }
    end

    def question
      q = {}
      iteration_data { |i, data|
        if data[i].is_a?(Array)
          q.update([data[:__cid__], i] => data[i])
        end
      }
      q
    end

    def update(answer)
      # not an answer of question?
      q = self.question
      answer.each_pair { |key, value|
        if !q[key] || !q[key].include?(value)
          return
        end
      }
      # update data
      iteration_data { |i, data|
        if data[i].is_a?(Array)
          a = answer[[data[:__cid__], i]]
          if a
            data[i] = create_node(a)
          end
        end
      }
      # expand data
      expand!
    end
  end

  Task.add(:tree_refresh) do
    Tree.refresh_database
    # tree = Tree.new(8)
    # tree.expand!
    # p tree.data
    # p tree.question
    # answer = { [8, "OUTCAR"] => 7 }
    # tree.update(answer)
    # p tree.data
    # p tree.question
  end

  # -- user -- #
  class User
    def task_trees
      prefix = "task_tree/"
      getdata_by(prefix)
    end

    def task_tree_insert(tid, cid)
      prefix = "task_tree/"
      tree = Tree.new(cid)
      save_data(prefix + tid, tree)
    end

    def task_tree_update(tid, answer_hash)
      prefix = "task_tree/"
      tree = load_data(prefix + tid)
      return if !tree
      tree.update(answer_hash)
      save_data(prefix + tid, tree)
    end

    def task_tree_delete(tid)
      prefix = "task_tree/"
      save_data(prefix + tid, nil)
    end

    # def task_tree_drop(tid, cid)
    #   prefix = "task_tree/"
    #   tree = load_data(prefix + tid)
    #   tree.drop(cid)
    #   save_data(prefix + tid, tree)
    # end
  end

  Task.add(:task_tree_insert) do |user, params|
    tid = params["tid"]
    cid = params["cid"].to_i
    User.new(user).task_tree_insert(tid, cid)
  end

  Task.add(:task_tree_delete) do |user, params|
    tid = params["tid"]
    User.new(user).task_tree_delete(tid)
  end
end
