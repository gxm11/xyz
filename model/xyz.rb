require "haml"
require "rdiscount"
require "crack"
require "json"
require "openssl"
require "persist"
require "sequel"

module XYZ
  class Tree; end
  class User; end
end

require "./model/xyz_db"
require "./model/xyz_task"
require "./model/xyz_auth"
require "./model/xyz_material"
require "./model/xyz_code"
require "./model/xyz_tree"
