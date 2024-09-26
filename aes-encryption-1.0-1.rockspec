package = "aes-encryption"
version = "1.0-1"

source = {
   url = "..." 
}

rockspec_format = "1.0"

description = {
  summary = "Kong plugin for AES encryption and decryption",
  detailed = [[
    This plugin decrypts incoming requests and encrypts outgoing responses using AES.
  ]],
  homepage = "https://example.com",
  license = "MIT",
}

dependencies = {
  "lua >= 5.1",
  "kong >= 2.0.0",
  "lua-openssl",
}

build = {
  type = "builtin",
  modules = {
    ["kong.plugins.aes-encryption.handler"] = "handler.lua",
    ["kong.plugins.aes-encryption.schema"] = "schema.lua",
    ["kong.plugins.aes-encryption"] = "init.lua",
  },
}
