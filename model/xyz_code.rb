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

  Task.add(:update_shared_file) do |user, params|
    tempfile = params["file"]["tempfile"]
    filename = params["file"]["filename"]
    FileUtils.cp(tempfile.path, "./user/#{user}/share/#{filename}")
  end

  Task.add(:delete_shared_file) do |user, params|
    filename = params["file"]
    FileUtils.rm("./user/#{user}/share/#{filename}")
  end

  Task.add(:rename_shared_file) do |user, params|
    old_fn = "./user/#{user}/share/" + params["old"]
    new_fn = "./user/#{user}/share/" + params["new"]
    FileUtils.mv(old_fn, new_fn)
  end

  Task.add(:update_code) do |user, params|
    cname = params["cname"]
    if cname != ""
      code = {}
      # - cname - #
      code["cname"] = cname
      # - description - #
      code["description"] = params["description"].strip.gsub(/\s*\n/, "\n")
      # - enable - #
      code["enable"] = !!params["enable"]
      # - cores - #
      code["cores"] = params["cores"].to_i
      # - input - #
      content = params["input"].strip.gsub(/\s*\n/, "\n")
      content = content.split("\n").collect { |line| line.split(";") }
      code["input"] = content
      # - entrance - #
      content = params["entrance"].strip.gsub(/\s*\n/, "\n")
      code["entrance"] = content
      # - output - #
      content = params["output"].strip.gsub(/\s*\n/, "\n")
      content = content.split("\n")
      code["output"] = content
      # - property - #
      content = params["output"].strip.gsub(/\s*\n/, "\n")
      content = content.split("\n")
      code["property"] = {}
      content.each do |line|
        ary = line.strip.split(/\s+/, 2)
        name = ary[0]
        type = ary[1] || "string"
        code["property"][name] = type
      end
      # - params - #
      code["params"] = params
      # -- update -- #
      User.new(user).calculation_code_update(cname, code)
    end
  end

  Task.add(:update_code_test) do |name, output, input|
    DB_Code.insert(
      name: name,
      author: "test",
      enable: true,
      input: JSON.dump(input),
      output: JSON.dump(output),
    )
  end
end
