require "fileutils"

if ARGV.include?("--reset")
  system "rm db/*; rm -r material/*; rm -r user/*"
else
  puts "use ruby reset.rb --reset"
end

if ARGV.include?("--test")
  require "./model/xyz"

  module XYZ
    Task.run(:add_active_key, "admin", "n" => "5")
    # -- user -- #
    activekey = DB_PS[:auth_active_key].last
    login_data = {
      "username" => "test", "password" => "t", "activekey" => activekey,
    }
    Task.run(:login_check, login_data)
    # -- materials -- #
    for i in 1..4
      params = {
        "name" => "test-#{i}",
        "files" => "<material><f>f</f><id>test-#{i}</id></material>",
      }
      Task.run(:insert_material, "test", params)
    end
    # -- collections -- #
    Task.run(:update_collection, "test", "cl_name" => "col-test", "mid" => ["1", "2", "3"])
    # -- codes -- #
    JSON.load(File.read("./test_code.json")).each do |params|
      Task.run(:update_code, "test", params)
    end
    # -- exit -- #
    puts "Finish init test, please run again."
  end
end
