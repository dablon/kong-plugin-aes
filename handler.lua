local BasePlugin = require "kong.plugins.base_plugin"
local openssl = require "openssl"
local aes = require "openssl.aes"
local cjson = require "cjson"

local AesHandler = BasePlugin:extend()

AesHandler.PRIORITY = 1000
AesHandler.VERSION = "1.0.0"

function AesHandler:new()
  AesHandler.super.new(self, "aes-encryption")
end

function AesHandler:access(conf)
  AesHandler.super.access(self)

  -- Decrypt request body
  local body = kong.request.get_raw_body()
  local decrypted_body = aes.decrypt(body, conf.aes_key, conf.aes_iv)
  kong.service.request.set_raw_body(decrypted_body)
end

function AesHandler:header_filter(conf)
  AesHandler.super.header_filter(self)

  -- Encrypt response body
  local body = kong.response.get_raw_body()
  local encrypted_body = aes.encrypt(body, conf.aes_key, conf.aes_iv)
  kong.response.set_raw_body(encrypted_body)
end

return AesHandler
