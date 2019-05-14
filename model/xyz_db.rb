module XYZ
  db = Sequel.connect("sqlite://./db/xyz.sqlite3")

  if !db.table_exists?(:user)
    db.create_table(:user) do
      primary_key :id
      string :name
      string :state
      string :passwd
      integer :level
    end
  end

  if !db.table_exists?(:code)
    db.create_table(:code) do
      primary_key :id
      string :name
      string :state
      string :author
      string :version
      string :input
      string :output
      text :entrance
    end
  end

  if !db.table_exists?(:material)
    db.create_table(:material) do
      primary_key :id
      string :name
      string :state
      string :info
    end
  end

  if !db.table_exists?(:calculation)
    db.create_table(:calculation) do
      primary_key :id
      string :state
      string :job_id
      timestamp :start_time
      timestamp :finish_time
    end
  end

  ps = Persist.new("./db/xyz.pstore")
  if !ps.key?(:auth_active_key)
    ps[:auth_active_key] = ["first-active-key"]
  end
  if !ps.key?(:auth_hmac_key)
    ps[:auth_hmac_key] = "xyz"
  end

  DB_PS = ps
  DB_User = db[:user]
  DB_Material = db[:material]
end
