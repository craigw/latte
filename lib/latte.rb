require 'null_logger'
require 'socket'
require 'bindata'
require 'pethau'

class Object
  include Pethau::InitializeWith
  include Pethau::DefaultValueOf
  include Pethau::PrivateAttrAccessor
end

require 'latte/hex_presenter'
require 'latte/address'
require 'latte/query'
require 'latte/response'
require 'latte/server'
require 'latte/version'
