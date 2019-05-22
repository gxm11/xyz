# encoding:utf-8

require "sinatra"
require "./model/xyz"

set :port, XYZ::Sinatra_Port
set :bind, "0.0.0.0"
set :server, "thin"
set :markdown, :layout_engine => :haml

enable :sessions
# -----------------------------------------------
# main
# -----------------------------------------------
get "/" do
  markdown :index
end

# -----------------------------------------------
# login
# -----------------------------------------------
get "/login" do
  haml :login
end

post "/login_check" do
  name = XYZ::Task.run(:login_check, params)
  if name
    key = name + "@" + request.ip
    session[:auth] = XYZ::Auth.set_auth(key)
    redirect "/work/#{name}/home"
  else
    redirect "/login"
  end
end

# -----------------------------------------------
# work / home
# -----------------------------------------------
get "/work" do
  key = XYZ::Auth.auth_key(session[:auth])
  if key
    name = key.split("@").first
    redirect "/work/#{name}/home"
  else
    redirect "/login"
  end
end

before "/work/:name/*" do
  key_auth = params[:name] + "@" + request.ip
  key = XYZ::Auth.auth_key(session[:auth])
  if key != key_auth
    redirect "/login"
  else
    @user = XYZ::User.new(params[:name])
  end
end

# -----------------------------------------------
# work / work
# -----------------------------------------------
get "/work/admin/active_keys" do
  @keys = XYZ::Auth.active_keys
  pass
end

get "/work/:name/materials" do
  @cl_name = params["cl_name"] || ""
  if @cl_name.split(".", 2).size == 2
    user, cl_name = @cl_name.split(".", 2)
    collection = XYZ::User.new(user).material_collections[cl_name]
  end
  if collection
    @collection = collection
    @cl_name = ""
  else
    @collection = @user.material_collections[@cl_name] || []
  end
  pass
end

get "/work/:name/update_code" do
  @cname = params["cname"] || ""
  if @cname.split(".", 2).size == 2
    user, cname = @cname.split(".", 2)
    code = XYZ::User.new(user).calculation_codes[cname]
  end
  if code
    @code = code
    @cname = ""
  else
    @code = @user.calculation_codes[@cname] || {}
  end
  pass
end

get "/work/:name/build_tree" do
  @tname = params["tname"] || ""
  @tree = @user.task_trees[@tname]
  pass
end

get "/work/:name/private_material" do
  @private_materials = XYZ::Material.materials(private: true, author: @user.name)
  pass
end

get "/work/:name/calculation" do
  @cl_name = params["cl_name"]
  @tname = params["tname"]
  @mids = @user.material_collections[@cl_name]
  @tree = @user.task_trees[@tname]
  @result, @info = XYZ::Plan.check(@tree, @mids)
  pass
end

# -----------------------------------------------
# render with template
# -----------------------------------------------
get "/work/:name/:work" do
  haml "work_#{params[:work]}".to_sym
end

# -----------------------------------------------
# task
# -----------------------------------------------
post "/task/v1/:task" do
  key = XYZ::Auth.auth_key(session[:auth])
  if key
    user = key.split("@").first
    task = params[:task].to_sym
    result = XYZ::Task.run(task, user, params)
    # -------------------------------------------
    # produce result
    # -------------------------------------------
    redirect request.referrer
  else
    redirect "/login"
  end
end

get "/task/v1/:task" do
  key = XYZ::Auth.auth_key(session[:auth])
  if key
    user = key.split("@").first
    task = params[:task].to_sym
    XYZ::Task.run(task, user, params)
    redirect request.referrer
  end
end

get "/task/v2/:task" do
  if request.ip == "127.0.0.1"
    task = params[:task].to_sym
    XYZ::Task.run(task, params)
  end
end
# -----------------------------------------------
# data
# -----------------------------------------------
get "/data" do
  @public_materials = XYZ::Material.materials(private: false)
  haml :data_home
end

get "/data/:mid/:name" do
  @m = XYZ::Material.material(params[:mid])
  haml :data_material
end

# -----------------------------------------------
# file
# -----------------------------------------------
get "/file/material/*" do
  fn = params["splat"].first
  send_file "./material/#{fn}"
end

get "/file/share/:user/*" do
  user = params["user"]
  fn = params["splat"].first
  send_file "./user/#{user}/share/#{fn}"
end

# -----------------------------------------------
# loop thread
# -----------------------------------------------
Thread.start {
  loop {
    sleep(30)
    # XYZ::Task.run(:update_plan)
  }
}
