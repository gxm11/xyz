# encoding:utf-8

require "ptools"
require "haml"
require "rdiscount"
require "crack"
require "json"
require "openssl"
require "persist"
require "sequel"

module XYZ
  class Tree; end

  module Plan
    Calculation = Struct.new(:tree, :mids, :user, :active)
  end

  Sinatra_Port = 4567
end

require "./model/xyz_db"
require "./model/xyz_auth"
require "./model/xyz_material"
require "./model/xyz_code"
require "./model/xyz_tree"
require "./model/xyz_task"
require "./model/xyz_plan"
