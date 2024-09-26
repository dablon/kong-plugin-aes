local AesHandler = require "kong.plugins.aes-encryption.handler"

local PLUGIN_NAME = "aes-encryption"

local schema = require("kong.plugins." .. PLUGIN_NAME .. ".schema")

return {
  name = PLUGIN_NAME,
  handler = AesHandler,
  schema = schema,
  config = schema.fields.config,
}
