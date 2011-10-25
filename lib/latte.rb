require 'null_logger'
require 'socket'
require 'ostruct'
require 'bindata'
require 'pethau'

class Object
  include Pethau::InitializeWith
  include Pethau::DefaultValueOf
  include Pethau::PrivateAttrAccessor
end

require 'latte/command_line'
require 'latte/address'
require 'latte/query'
require 'latte/server'
require 'latte/version'
