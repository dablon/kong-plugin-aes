local typedefs = require "kong.db.schema.typedefs"

return {
  name = "aes-encryption",
  fields = {
    {
      config = {
        type = "record",
        fields = {
          { aes_key = { type = "string", required = true } },
          { aes_iv = { type = "string", required = true } },
        },
      },
    },
  },
}
