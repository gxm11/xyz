# encoding:utf-8

module XYZ
  class User
    def calculation_codes
      prefix = "calculation_code/"
      getdata_by(prefix)
    end

    def calculation_code_update(cname, code)
      prefix = "calculation_code/"
      old_code = getdata_by(prefix + cname).values.first
      if old_code.nil?
        DB_Code.insert(
          name: cname,
          author: @name,
          enable: !!code["enable"],
          cores: code["cores"].to_i,
          input: JSON.dump(code["input"]),
          output: JSON.dump(code["output"]),
          entrance: code["entrance"],
          property: JSON.dump(code["property"]),
          description: code["description"],
        )
        need_refresh = true
      else
        DB_Code.where(name: cname, author: @name).update(
          enable: !!code["enable"],
          cores: code["cores"].to_i,
          input: JSON.dump(code["input"]),
          output: JSON.dump(code["output"]),
          entrance: code["entrance"],
          property: JSON.dump(code["property"]),
          description: code["description"],
          update_at: Sequel::CURRENT_TIMESTAMP,
        )
        need_refresh = ["input", "output", "enable"].inject(false) { |ret, i|
          ret || old_code[i] != code[i]
        }
      end
      save_data(prefix + cname, code)
      # -- refresh database -- #
      if need_refresh
        Tree.refresh_database
      end
    end
  end
end
