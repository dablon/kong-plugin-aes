  
package = "kong-plugin-aes-crypto"
version = "0.1.0-1"
source = {
  url = "https://github.com/dablon/kong-plugin-aes",
  tag = "0.1.0"
}
description = {
  summary = "A Kong plugin for AES encryption and decryption",
  detailed = [[
    This plugin provides AES encryption and decryption capabilities for Kong.
  ]],
  homepage = "https://github.com/dablon/kong-plugin-aes",
  license = "MIT"
}
dependencies = {
  "lua >= 5.1",
  "kong >= 2.0.0",
  "lua-openssl"
}
build = {
  type = "builtin",
  modules = {
    ["kong.plugins.aes-crypto.handler"] = "handler.lua",
    ["kong.plugins.aes-crypto.schema"] = "schema.lua",
    ["kong.plugins.aes-crypto.api"] = "api.lua"
  }
}