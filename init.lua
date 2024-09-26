local openssl = require("openssl")

local function encrypt(data)
  local encrypted_data = openssl.encrypt(data, "AES-256-CBC", "your_secret_key")
  return encrypted_data
end

local function decrypt(data)
  local decrypted_data = openssl.decrypt(data, "AES-256-CBC", "your_secret_key")
  return decrypted_data
end

local function access(plugin_conf)
  local data = ngx.req.get_body_data()
  local encrypted_data = encrypt(data)
  ngx.req.set_body_data(encrypted_data)
end

local function body_filter(plugin_conf)
  local data = ngx.arg[1]
  local decrypted_data = decrypt(data)
  ngx.arg[1] = decrypted_data
end

return {
  access = access,
  body_filter = body_filter
}