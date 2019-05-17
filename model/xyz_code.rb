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
end
