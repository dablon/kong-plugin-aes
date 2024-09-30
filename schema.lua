local typedefs = require "kong.db.schema.typedefs"

return {
  name = "aes-crypto",
  fields = {
    { consumer = typedefs.no_consumer },
    { protocols = typedefs.protocols_http },
    { config = {
        type = "record",
        fields = {
          { encrypt_request = { type = "boolean", default = true } },
          { decrypt_response = { type = "boolean", default = true } },
          { encryption_key = { type = "string", required = true, encrypted = true } },
          { encryption_iv = { type = "string", required = true, encrypted = true } },
        },
      },
    },
  },
}