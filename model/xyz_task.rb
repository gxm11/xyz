# encoding:utf-8

module XYZ
  module Task
    @data = {}

    module_function

    def add(name, &block)
      @data[name] = { proc: block, name: name }
    end

    def run(name, *args)
      if @data.include?(name)
        return @data[name][:proc].call(*args)
      end
    end

    attr_reader :data
  end
end

# -----------------------------------------------
# All Tasks
# -----------------------------------------------

module XYZ
  # ---------------------------------------------
  # Auth
  # ---------------------------------------------
  Task.add(:login_check) do |params|
    name = params["username"]
    passwd = params["password"]
    key = params["activekey"]
    user = Auth::login_check(name, passwd, key)
    user ? user[:name] : nil
  end

  Task.add(:add_active_key) do |user, params|
    if user == "admin"
      DB_PS.transaction do |db|
        params["n"].to_i.times do
          key = OpenSSL::Random.random_bytes(12).unpack("H*").first
          [5, 10, 15].each { |i| key[i] = "-" }
          db[:auth_active_key].push(key)
        end
      end
    end
  end

  # ---------------------------------------------
  # Material
  # ---------------------------------------------
  Task.add(:insert_material) do |user, params|
    name = params["name"]
    if name != ""
      files = Crack::XML.parse(params["files"])["material"] || {}
      mid = Material.insert(name, files)
      Material.update(mid, author: user)
      if params["private"] == "private"
        Material.update(mid, private: true)
      end
    end
  end

  Task.add(:upload_material_file) do |user, params|
    tempfile = params["file"]["tempfile"]
    if params["filename"] == ""
      filename = params["file"]["filename"]
    else
      filename = params["filename"]
    end
    mid = params["mid"].to_i
    m = XYZ::Material.material(mid)
    if m[:author] == user
      FileUtils.cp(tempfile.path, "./material/#{mid}/#{filename}")
    end
  end

  Task.add(:update_collection) do |user, params|
    cl_name = params["cl_name"]
    mids = params["mid"]
    if mids
      mids = mids.collect { |mid| mid.to_i }
    end
    if cl_name != ""
      User.new(user).material_collection_update(cl_name, mids)
    end
  end

  # ---------------------------------------------
  # Code
  # ---------------------------------------------
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
      content = content.split("\n")
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

  # ---------------------------------------------
  # Tree
  # ---------------------------------------------
  Task.add(:task_tree_insert) do |user, params|
    tname = params["tname"]
    cid = params["cid"].to_i
    User.new(user).task_tree_insert(tname, cid)
  end

  Task.add(:task_tree_delete) do |user, params|
    tname = params["tname"]
    User.new(user).task_tree_delete(tname)
  end

  Task.add(:task_tree_update) do |user, params|
    tname = params["tname"]
    answer_hash = {}
    params.each_pair do |k, v|
      if v =~ /^\d+$/
        answer_hash[k] = v.to_i
      end
    end
    User.new(user).task_tree_update(tname, answer_hash)
  end

  Task.add(:task_tree_remove_node) do |user, params|
    tname = params["tname"]
    cid = params["cid"].to_i
    User.new(user).task_tree_remove_node(tname, cid)
  end

  Task.add(:task_tree_clone) do |user, params|
    tname = params["tname"]
    t = params["tname2"]
    if tname.split(".", 2).size == 2
      _user, _t = tname.split(".", 2)
      tree = User.new(_user).task_trees[_t]
      if tree
        User.new(user).task_tree_clone(t, tree)
      end
    end
  end

  # -----------------------------------------------
  # Plan
  # -----------------------------------------------
  Task.add(:insert_plan) do |user, params|
    u = User.new(user)
    cl_name = params["cl_name"]
    tname = params["tname"]
    comment = params["comment"]
    mids = u.material_collections[cl_name]
    tree = u.task_trees[tname]
    pid = XYZ::Plan.insert(tree, mids, user)
    u.insert_plan(pid, comment)
  end

  Task.add(:update_plan) do
    XYZ::Plan.update_plan
  end

  Task.add(:calculation_start) do |params|
    calc_id = params["calc_id"].to_i
    XYZ::Plan.calculation_start(calc_id)
  end

  Task.add(:calculation_finish) do |params|
    calc_id = params["calc_id"].to_i
    XYZ::Plan.calculation_finish(calc_id)
  end
end

# -----------------------------------------------
# Run
# -----------------------------------------------
XYZ::Tree.refresh_database
