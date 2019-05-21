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
            path = input_file_get(mid, child_cid, input)
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
            return "./user/#{user}/share/#{fn}"
          end
        end
        # use file in another calculation?
        if i.start_with?("calculation.")
          _, _id, fn = i.split(".", 3)
          if File.exist?("./calculation/#{_id}/#{fn}")
            return "./calculation/#{_id}/#{fn}"
          end
        end
        # use file in another material
        if i.start_with?("material.")
          _, _id, fn = i.split(".", 3)
          if File.exist?("./material/#{_id}/#{fn}")
            return "./material/#{_id}/#{fn}"
          end
        end
        # search child calculation
        # if failed -> search material folder
        folders.each do |folder|
          if File.exist?(folder + "/" + i)
            return folder + "/" + i
          end
        end
      end
      return nil
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

    def update
      if ready_for_next_submit?
        material_id, code_id = random_choose_one_task
        prepare_folder(material_id, code_id)
      end
    end

    def random_choose_one_task
      [0, 0]
    end

    def ready_for_next_submit?
      false
    end

    def prepare_folder(mid, cid)
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
