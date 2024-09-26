local kong = kong
local openssl_cipher = require "resty.openssl.cipher"
local str = require "resty.string"

local AESHandler = {}

AESHandler.PRIORITY = 1000
AESHandler.VERSION = "0.1.0"

-- Helper function to encrypt data
local function encrypt(data, key, iv)
    local cipher = assert(openssl_cipher.new("AES-256-CBC"))
    local encrypted = cipher:encrypt(key, iv, data)
    return str.to_hex(encrypted)
end

-- Helper function to decrypt data
local function decrypt(data, key, iv)
    local cipher = assert(openssl_cipher.new("AES-256-CBC"))
    local decrypted = cipher:decrypt(key, iv, str.to_bin(data))
    return decrypted
end

function AESHandler:access(conf)
    kong.log.debug("AES plugin access phase")
    
    -- Only proceed if we're configured to encrypt the request
    if not conf.encrypt_request then
        return
    end

    local body, err = kong.request.get_raw_body()
    if err then
        kong.log.err("Failed to read request body: ", err)
        return kong.response.exit(400, { message = "Bad request" })
    end

    if body then
        local encrypted_body = encrypt(body, conf.encryption_key, conf.encryption_iv)
        kong.service.request.set_raw_body(encrypted_body)
        kong.service.request.set_header("Content-Type", "text/plain")
    end
end

function AESHandler:header_filter(conf)
    kong.log.debug("AES plugin header filter phase")
    
    -- Only proceed if we're configured to decrypt the response
    if not conf.decrypt_response then
        return
    end

    kong.response.clear_header("Content-Length")
    kong.response.set_header("Content-Type", "application/json")
end

function AESHandler:body_filter(conf)
    kong.log.debug("AES plugin body filter phase")
    
    -- Only proceed if we're configured to decrypt the response
    if not conf.decrypt_response then
        return
    end

    local chunk, eof = ngx.arg[1], ngx.arg[2]

    if not eof then
        -- If it's not the last chunk, don't do anything
        return
    end

    -- Get the full response body
    local body = kong.response.get_raw_body()
    
    if body then
        local decrypted_body = decrypt(body, conf.encryption_key, conf.encryption_iv)
        ngx.arg[1] = decrypted_body
    else
        ngx.arg[1] = chunk
    end
end

return AESHandler