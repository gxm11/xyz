# encoding: utf-8

# Plan 是实际执行的内容，包括制定、管理、执行计划

module XYZ
  module Plan
    STATE_SLEEP = "SLEEP"
    STATE_WAIT = "WAIT"
    STATE_CANCEL = "CANCEL"
    STATE_RUN = "RUN"
    STATE_DONE = "DONE"
    STATE_ERROR = "ERROR"
    STATE_ABORT = "ABORT"

    module_function

    def check(tree, mids)
      result = {}
      info = {}
      # 逐一检测每个材料是否满足条件
      for mid in mids
        # next: 需要马上计算的节点
        # skip: 无需计算的节点
        # unready: 缺少计算条件的节点（一定在 next 中）
        # done: 已经完成的节点
        tree_nodes = tree.nodes
        nodes = { next: [], unready: [], done: [], run: [], wait: [] }
        # 获取 done, run 和 wait 的节点
        rows = DB_Calculation.select(:code_id, :state).where(material_id: mid).all
        rows.each do |calc|
          next if !tree_nodes.include?(calc[:code_id])
          case calc[:state]
          when STATE_DONE then nodes[:done] << calc[:code_id]
          when STATE_RUN then nodes[:run] << calc[:code_id]
          when STATE_WAIT then nodes[:wait] << calc[:code_id]
          end
        end
        # 获取 next nodes
        nodes[:next] = tree.next_nodes(nodes[:done])
        # 判断 next 是否是 unready 状态
        for cid in nodes[:next]
          data = tree.node_data(cid)
          for input, child_cid in data
            next if input == :__cid__
            i, path = input_file_get(mid, child_cid, input)
            if !path
              nodes[:unready] << cid
              if !info["#{mid}/#{cid}/unready"]
                info["#{mid}/#{cid}/unready"] = [input]
              else
                info["#{mid}/#{cid}/unready"] << input
              end
            end
          end
        end
        nodes.values.uniq!
        result[mid] = nodes
      end
      return result, info
    end

    def input_file_get(material_id, code_id, input)
      folders = []
      if code_id != 0
        calc_id = DB_Calculation.select(:id).where(
          material_id: material_id, code_id: code_id, state: STATE_DONE,
        ).all.last[:id]
        folders << "./calculation/#{calc_id}"
      end
      folders << "./material/#{material_id}"
      for i in input.split(";")
        # use shared file?
        if i.start_with?("share.")
          _, user, fn = i.split(".", 3)
          if File.exist?("./user/#{user}/share/#{fn}")
            return [i, "./user/#{user}/share/#{fn}"]
          end
        end
        # use file in another calculation?
        if i.start_with?("calculation.")
          _, _id, fn = i.split(".", 3)
          if File.exist?("./calculation/#{_id}/#{fn}")
            return [i, "./calculation/#{_id}/#{fn}"]
          end
        end
        # use file in another material
        if i.start_with?("material.")
          _, _id, fn = i.split(".", 3)
          if File.exist?("./material/#{_id}/#{fn}")
            return [i, "./material/#{_id}/#{fn}"]
          end
        end
        # search child calculation
        # if failed -> search material folder
        folders.each do |folder|
          if File.exist?(folder + "/" + i)
            return [i, folder + "/" + i]
          end
        end
      end
      return [nil, nil]
    end

    def insert(tree, mids, user)
      pid = nil
      DB_PS.transaction do |db|
        pid = db[:calculation_plan].keys.max || 0
        pid += 1
        db[:calculation_plan][pid] = Calculation.new(
          tree, mids, user, true
        )
      end
      return pid
    end

    def calculation_plan(pid)
      DB_PS[:calculation_plan][pid]
    end

    def avaliable_tasks
      avaliable_tasks = []
      # 1. 检查所有的计划，统计任务列表
      for plan_id, plan in DB_PS[:calculation_plan]
        # 1.1 跳过不活跃的计划
        next if !plan.active
        active = false
        # 1.2 对每一个计划，遍历全部的材料
        for material_id in plan.mids
          # 从数据库中读取信息
          info = DB_Calculation.select(:code_id, :state).where(
            material_id: material_id,
          ).all
          # 已经完成的部分
          done = info.select { |row|
            row[:state] == STATE_DONE
          }.collect { |row| row[:code_id] }
          # 已经提交的部分
          submit = info.select { |row|
            row[:state] != STATE_DONE
          }.collect { |row| row[:code_id] }
          # 如果没有提交，任务将会加入
          for code_id in plan.tree.next_nodes(done)
            next if submit.include?(code_id)
            active = true
            avaliable_tasks << [plan_id, material_id, code_id]
          end
        end
        if active == false
          DB_PS.transaction do |db|
            db[:calculation_plan][plan_id].active = false
          end
        end
      end
      return avaliable_tasks
    end

    # 这里需要根据具体的 PBS 系统调整
    def check_pbs_state
      state = {} # calc_id => state
      user = `whoami`.strip
      result = `qstat -u #{user} | grep .w003`
      result.split("\n").each do |line|
        words = line.split
        q, name, s = words[2], words[3], words[9]
        state[q] ||= []
        s = STATE_ERROR
        s = STATE_RUN if s == "R"
        s = STATE_SLEEP if s == "Q"
        state[q] << [name, s]
      end
      return state
    end

    def update_plan
      tasks = avaliable_tasks
      states = check_pbs_state
      # 对 queue: cmt 进行处理
      [["cmt", 2]].each do |q, n_jobs|
        states[q] ||= []
        # 对之前标记为 wait 和 run 的计算，
        # 如果从 states 里消失了，则标记为 error
        jobs = states[q].select { |name, s|
          name.start_with?("xyz.")
        }.collect { |name, s|
          name[4..-1]
        }
        _wait = DB_Calculation.where(queue: q, state: STATE_WAIT).all
        _run = DB_Calculation.where(queue: q, state: STATE_RUN).all
        _cancel = _wait.collect { |row| row[:id] } - jobs
        _error = _run.collect { |row| row[:id] } - jobs
        DB_Calculation.where { _cancel.include?(id) }.update(state: STATE_ERROR)
        DB_Calculation.where { _error.include?(id) }.update(state: STATE_ERROR)
        # 如果睡眠的任务较少，则新增几个睡眠任务
        n_sleep = states[q].select { |name, s| s == STATE_SLEEP }.size
        if n_sleep < n_jobs
          ret = wakeup_calculation(q)
          if !ret
            prepare_calculation(q, tasks.sample(n_jobs))
          end
        end
      end
    end

    def wakeup_calculation(queue)
      sleep = DB_Calculation.where(queue: queue, state: STATE_SLEEP).all
      for calculation in sleep
        calc_id = calculation[:id]
        ret = system("cd ./calculation/#{calc_id} && qsub -q #{queue} run.xyz.sh")
        if ret
          DB_Calculation.where(id: calc_id).update(state: STATE_WAIT)
        end
      end
      return !sleep.empty?
    end

    def prepare_calculation(queue, tasks)
      for plan_id, material_id, code_id in tasks
        code = Tree::Codes[code_id]
        calc_id = DB_Calculation.insert(
          material_id: material_id,
          code_id: code_id,
          queue: queue,
        )
        folder = "./calculation/#{calc_id}"
        FileUtils.mkdir(folder)
        plan = calculation_plan(plan_id)
        data = plan.tree.node_data(code_id)
        for input, child_cid in data
          next if input == :__cid__
          i, path = input_file_get(material_id, child_cid, input)
          FileUtils.cp(path, folder + "/" + i)
        end
        sh = run_xyz_sh(calc_id, material_id, code_id)
        IO.binwrite(folder + "/" + "run.xyz.sh", sh)
        DB_Calculation.where(id: calc_id).update(state: STATE_SLEEP)
      end
    end

    def run_xyz_sh(calc_id, material_id, code_id)
      code = DB_Code.where(id: code_id).first
      callback_url = "http://#{Sinatra_Host}:#{Sinatra_Port}/task/v2"

      sh = <<~PBS_SCRIPT
        #PBS -N xyz.#{calc_id}
        #PBS -l nodes=1:ppn=#{code[:cores]}
        #PBS -l Qlist=n24
        
        curl #{callback_url}/calculation_start?calc_id=#{calc_id}

        date > output.$PBS_JOBID        
        cd $PBS_O_WORKDIR
        cp $PBS_NODEFILE node        

        # Entrance Code Here #
        #{code[:entrance]}
        # Entrance Code Here #

        date >> output.$PBS_JOBID
        curl #{callback_url}/calculation_finish?calc_id=#{calc_id}       
      PBS_SCRIPT

      return sh
    end

    def calculation_start(calc_id)
      DB_Calculation.where(id: calc_id).update(state: STATE_RUN)
    end

    def calculation_finish(calc_id)
      DB_Calculation.where(id: calc_id).update(state: STATE_DONE)
    end
  end

  class User
    def insert_plan(pid, comment)
      plans = load_data("plans") || {}
      plans[pid] = comment
      save_data("plans", plans)
    end

    def plan_remove_materials(pid, mids = [])
      plans = load_data("plans")
      if plans.keys.include?(pid)
        # do sth
      end
    end

    def calculation_plans
      load_data("plans") || {}
    end
  end
end
