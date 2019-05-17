# encoding:utf-8

module XYZ
  class User
    def calculation_codes
      prefix = "calculation_code/"
      getdata_by(prefix)
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
end
