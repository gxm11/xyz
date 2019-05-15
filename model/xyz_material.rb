# encoding:utf-8

module XYZ
  module Material
    module_function

    def insert(name, info)
      mid = DB_Material.insert(
        name: name,
        state: "",
        info: JSON.dump(info.keys),
      )
      folder = "./materials/#{mid}"
      Dir.mkdir(folder)
      info.each_pair do |key, value|
        next if !value
        value = value.strip.gsub("\r\n", "\n")
        File.binwrite("#{folder}/#{key}", value)
      end
      return mid
    end

    def update(mid, update_hash)
      DB_Material.where(id: mid).update(update_hash)
    end

    def delete(mid)
      DB_Material.where(id: mid).delete
    end

    def material(mid)
      DB_Material.where(id: mid).first
    end

    def materials(select_hash = {})
      DB_Material.where(select_hash).all
    end
  end

  # ---------------------------------------------
  # user
  # ---------------------------------------------
  class User
    alias _in_material_db_init db_init

    def db_init
      _in_material_db_init
      key = pskey "material_collections"
      DB_PS[key] = {}
    end

    def material_collections
      key = pskey "material_collections"
      DB_PS[key]
    end

    def material_collection_update(cid, mids)
      key = pskey "material_collections"
      DB_PS.transaction do |db|
        if mids
          db[key][cid] = mids.collect { |id| id.to_i }
        else
          db[key].delete(cid)
        end
      end
    end

    def materials
      ms = DB_Material.all
      ms.sort { |m1, m2| m1[:id] <=> m2[:id] }
    end
  end

  # ---------------------------------------------
  # tasks
  # ---------------------------------------------
  Task.add(:insert_material) do |user, params|
    name = params["name"]
    if name != ""
      info = Crack::XML.parse(params["info"])["material"] || {}
      mid = Material.insert(name, info)
      if params["pravite"] == "pravite"
        Material.update(mid, state: user)
      end
    end
  end

  Task.add(:update_collection) do |user, params|
    cid = params["cid"]
    mid = params["mid"]
    if cid != ""
      User.new(user).material_collection_update(cid, mid)
    end
  end
end
