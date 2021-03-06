# encoding:utf-8

module XYZ
  module Material
    module_function

    def insert(name, files)
      mid = DB_Material.insert(name: name)
      folder = "./material/#{mid}"
      FileUtils.mkdir(folder, mode: 0755)
      files.each_pair do |path, content|
        next if !content
        content = content.strip.gsub(/\s*\n/, "\n")
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
      getdata_by(prefix)
    end

    def material_collection_update(cl_name, mids)
      prefix = "material_collection/"
      save_data(prefix + cl_name, mids)
    end

    def materials
      ms = DB_Material.where(
        Sequel.or(private: false, author: @name)
      ).order(:id).all
    end
  end
end
