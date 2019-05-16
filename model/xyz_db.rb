module XYZ
  db = Sequel.connect("sqlite://./db/xyz.sqlite3")
  # save user data / password
  if !db.table_exists?(:user)
    db.create_table(:user) do
      primary_key :id
      string :name, unique: true, null: false
      string :passwd
      integer :level, default: 0
      timestamp :create_at, default: Sequel::CURRENT_TIMESTAMP

      index [:name]
    end
  end

  # material properties
  if !db.table_exists?(:material)
    db.create_table(:material) do
      primary_key :id
      string :name, null: false
      string :author
      bool :pravite, default: false
    end
  end

  # save code input / output
  # can be search by output
  if !db.table_exists?(:code)
    db.create_table(:code) do
      primary_key :id
      string :name, null: false
      string :author
      bool :enable, default: false
      string :input
      string :output
      text :entrance
      timestamp :last_update_time
    end
  end

  # all calculations
  if !db.table_exists?(:calculation)
    db.create_table(:calculation) do
      primary_key :id
      string :material_id, null: false
      string :code_id, null: false
      timestamp :create_at, default: Sequel::CURRENT_TIMESTAMP
      timestamp :start_at
      timestamp :finish_at
      string :state, default: "SLEEP"
    end
  end

  # NoSQL database
  ps = Persist.new("./db/xyz.pstore")
  # material collections and task trees
  # it should save in No SQL database

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
