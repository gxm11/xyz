# encoding:utf-8

module XYZ
  class User
    def calculation_codes
      prefix = "calculation_code/"
      getdata_by(prefix)
    end

    def calculation_code_update(cname, code)
      prefix = "calculation_code/"
      if getdata_by(prefix + cname).empty?
        DB_Code.insert(
          name: cname,
          author: @name,
          enable: !!code["enable"],
          input: JSON.dump(code["input"]),
          output: JSON.dump(code["output"]),
        )
      else
        DB_Code.where(name: cname, author: @name).update(
          enable: !!code["enable"],
          input: JSON.dump(code["input"]),
          output: JSON.dump(code["output"]),
          update_at: Sequel::CURRENT_TIMESTAMP,
        )
      end
      save_data(prefix + cname, code)
    end
  end
end
