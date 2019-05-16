require "sinatra"
require "./model/xyz"

set :port, 4567
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
  name = XYZ::Task.run(:login_check, @params)
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
  key_auth = @params[:name] + "@" + request.ip
  key = XYZ::Auth.auth_key(session[:auth])
  if key != key_auth
    redirect "/login"
  else
    @user = XYZ::User.new(@params[:name])
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
  @cid = @params[:cid] || ""
  if @cid.split(".", 2).size == 2
    user, cid = @cid.split(".", 2)
    collection = XYZ::User.new(user).material_collections[cid]
  end
  if collection
    @collection = collection
    @cid = ""
  else
    @collection = @user.material_collections[@cid] || []
  end
  pass
end

get "/work/:name/update_code" do
  @cid = @params[:cid] || ""
  if @cid.split(".", 2).size == 2
    user, cid = @cid.split(".", 2)
    code = XYZ::User.new(user).calculation_codes[cid]
  end
  if code
    @code = code
    @cid = ""
  else
    @code = @user.calculation_codes[@cid] || {}
  end
  pass
end

# -----------------------------------------------
# render with template
# -----------------------------------------------
get "/work/:name/:work" do
  haml "work_#{@params[:work]}".to_sym
end

# -----------------------------------------------
# task
# -----------------------------------------------
post "/task/:v/:task" do
  key = XYZ::Auth.auth_key(session[:auth])
  if key
    user = key.split("@").first
    task = @params[:task].to_sym
    result = XYZ::Task.run(task, user, @params)
    # -------------------------------------------
    # produce result
    # -------------------------------------------
    case @params[:v]
    when "v1" # v1: Back to referrer
      redirect request.referrer
    end
  else
    redirect "/login"
  end
end

get "/task/v1/:task" do
  key = XYZ::Auth.auth_key(session[:auth])
  if key
    user = key.split("@").first
    task = @params[:task].to_sym
    XYZ::Task.run(task, user, @params)
    redirect request.referrer
  end
end

# -----------------------------------------------
# data
# -----------------------------------------------
get "/data" do
  @materials = XYZ::Material.materials()
  haml :data_home
end

get "/data/:mid/:name" do
  @m = XYZ::Material.material(@params[:mid])
  haml :data_material
end

# -----------------------------------------------
# file
# -----------------------------------------------
get "/file/material/*" do
  fn = params["splat"].first
  send_file "./material/#{fn}"
end
