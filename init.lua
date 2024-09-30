local aes = require "resty.aes"
local str = require "resty.string"

local AESCrypto = {}

AESCrypto.PRIORITY = 1000
AESCrypto.VERSION = "0.1.0"

function AESCrypto:new()
  return setmetatable({}, { __index = self })
end

function AESCrypto:access(conf)
  if not conf.encrypt_request then
    return
  end

  local body, err = kong.request.get_raw_body()
  if err then
    kong.log.err("Failed to read request body: ", err)
    return kong.response.exit(400, { message = "Bad request" })
  end

  if body then
    local cipher = aes:new(conf.encryption_key, conf.encryption_iv)
    local encrypted = cipher:encrypt(body)
    kong.service.request.set_raw_body(str.to_hex(encrypted))
    kong.service.request.set_header("Content-Type", "text/plain")
  end
end

function AESCrypto:body_filter(conf)
  if not conf.decrypt_response then
    return
  end

  local chunk, eof = ngx.arg[1], ngx.arg[2]

  if not eof then
    return
  end

  local body = kong.response.get_raw_body()
  
  if body then
    local cipher = aes:new(conf.encryption_key, conf.encryption_iv)
    local decrypted = cipher:decrypt(str.to_bin(body))
    ngx.arg[1] = decrypted
  else
    ngx.arg[1] = chunk
  end
end

return AESCrypto