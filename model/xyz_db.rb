# encoding:utf-8

module XYZ
  # ---------------------------------------------
  # Database
  # ---------------------------------------------
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
      bool :private, default: false
      timestamp :create_at, default: Sequel::CURRENT_TIMESTAMP
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
      text :input
      text :output
      text :entrance
      text :property
      text :description
      timestamp :update_at, default: Sequel::CURRENT_TIMESTAMP
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
  DB_Code = db[:code]
  DB_Calculation = db[:calculation]
  # ---------------------------------------------
  # User
  # ---------------------------------------------
  # Each user has private or shared data
  # ---------------------------------------------
  class User
    attr_reader :name

    def initialize(name)
      @name = name
    end

    def pskey(key)
      "#{name}/#{key}".to_sym
    end

    def save_data(key, value)
      if value == nil
        DB_PS.delete(pskey(key))
      else
        DB_PS[pskey(key)] = value
      end
    end

    def load_data(key)
      DB_PS[pskey(key)]
    end

    def getdata_by(prefix)
      _prefix = pskey(prefix).to_s
      len = _prefix.size
      keys = DB_PS.keys.select { |key|
        key[0, len] == _prefix
      }
      values = keys.collect { |k| DB_PS[k] }
      short_keys = keys.collect { |k| k[len..-1] }
      Hash[short_keys.zip(values)]
    end

    def db_init
      FileUtils.mkdir("./user/#{@name}", mode: 0755)
      FileUtils.mkdir("./user/#{@name}/share", mode: 0755)
      FileUtils.mkdir("./user/#{@name}/code", mode: 0755)
    end
  end
end
