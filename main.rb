# encoding:utf-8

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

# -----------------------------------------------
# render with template
# -----------------------------------------------
get "/work/:name/:work" do
  haml "work_#{params[:work]}".to_sym
end

# -----------------------------------------------
# task
# -----------------------------------------------
post "/task/:v/:task" do
  key = XYZ::Auth.auth_key(session[:auth])
  if key
    user = key.split("@").first
    task = params[:task].to_sym
    result = XYZ::Task.run(task, user, params)
    # -------------------------------------------
    # produce result
    # -------------------------------------------
    case params[:v]
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
    task = params[:task].to_sym
    XYZ::Task.run(task, user, params)
    redirect request.referrer
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
# test
# -----------------------------------------------
# get "/test/" do
#   # - user - #
#   passwd = OpenSSL::HMAC.hexdigest("SHA256", XYZ::Auth::HMAC_KEY, "test")
#   XYZ::DB_User.insert(name: "test", passwd: passwd)
#   user = XYZ::User.new("test")
#   # - materials - #
#   XYZ::Material.insert("test-01", {})
#   XYZ::Material.insert("test-02", {})
#   XYZ::Material.insert("test-03", {})
#   # - collections - #
#   user.material_collection_update("test", [1, 2, 3])
#   # - codes - #
#   codes = []
#   codes << ["share_data", ["incar_template"], []]
#   codes << ["base_data", ["lattice_vector", "atomic_frac"], []]
#   codes << ["poscar_v0", ["POSCAR"], ["lattice_vector", "atomic_frac"]]
#   codes << ["kpoints_v0", ["KPOINTS"], ["lattice_vector"]]
#   codes << ["potcar_v0", ["POTCAR"], ["atomic_frac"]]
#   codes << ["incar_v0", ["INCAR"], ["incar_template", "atomic_frac"]]
#   codes << ["vasp_v0", ["OUTCAR"], ["INCAR", "POSCAR", "KPOINTS", "POTCAR"]]
#   codes << ["band", ["band.png"], ["OUTCAR"]]

#   codes.each do |code|
#     XYZ::Task.run(:update_code_test, *code)
#   end

#   redirect "/login"
# end
