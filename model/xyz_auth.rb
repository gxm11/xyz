# encoding:utf-8

module XYZ
  module Auth
    # table user
    @cache = {}
    HMAC_KEY = DB_PS[:auth_hmac_key]

    module_function

    def login_check(name, passwd, key)
      # 0. hmac password
      passwd = OpenSSL::HMAC.hexdigest("SHA256", HMAC_KEY, passwd)
      # if there's not active key
      if key == ""
        user = DB_User.where(name: name).first
        user_valid = user && user[:passwd] == passwd
        return user_valid ? user : nil
      end
      user = DB_User.where(name: name).first
      if user.nil? && name != ""
        uid = nil
        DB_PS.transaction do |db|
          if db[:auth_active_key].include?(key)
            db[:auth_active_key].delete(key)
            uid = DB_User.insert(name: name, passwd: passwd)
          end
        end
        if uid
          User.new(name).db_init
        end
        return DB_User.where(name: name).first
      end
    end

    def set_auth(key)
      auth = [OpenSSL::Random.random_bytes(64)].pack("m0")
      @cache[key] = auth
      return auth
    end

    def auth_key(auth)
      @cache.key(auth)
    end

    def active_keys
      DB_PS[:auth_active_key]
    end
  end

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
    end
  end

  Task.add(:login_check) do |params|
    name = params[:username]
    passwd = params[:password]
    key = params[:activekey]
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
end
