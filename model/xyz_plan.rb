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
      result = []
      # 逐一检测每个材料是否满足条件
      for mid in mids
        rows = DB_Calculation.select(:code_id).where(material_id: mid, state: STATE_DONE).all
        finished_nodes = rows.collect { |r| r[:code_id] }
        next_nodes = tree.next_nodes(finished_nodes)
        for cid in next_nodes
          data = tree.node_data(cid)
          for input, next_cid in data
            next if input == :__cid__
            path = input_file_get(mid, next_cid, input)
            if !path
              result << [mid, cid, input]
            end
          end
        end
      end
      return result
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
        else
          folders.each do |folder|
            if File.exist?(folder + "/" + i)
              return folder + "/" + i
            end
          end
        end
      end
      return nil
    end
  end
end
