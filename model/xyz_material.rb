# encoding:utf-8

module XYZ
  module Material
    module_function

    def insert(name, files)
      mid = DB_Material.insert(
        name: name,
      )
      folder = "./materials/#{mid}"
      Dir.mkdir(folder)
      files.each_pair do |path, content|
        next if !content
        content = content.strip.gsub("\r\n", "\n")
        File.binwrite("#{folder}/#{path}", content)
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
    def material_collections
      prefix = "material_collection/"
      iterate_prefix(prefix) { |k, v| v }
    end

    def material_collection_update(cid, mids)
      prefix = "material_collection/"
      if mids
        save_data(prefix + cid, mids)
      else
        save_data(prefix + cid, nil)
      end
    end

    def materials
      ms = DB_Material.order(:id).all
    end
  end

  # ---------------------------------------------
  # tasks
  # ---------------------------------------------
  Task.add(:insert_material) do |user, params|
    name = params["name"]
    if name != ""
      files = Crack::XML.parse(params["files"])["material"] || {}
      mid = Material.insert(name, files)
      if params["private"] == "private"
        Material.update(mid, private: true)
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
