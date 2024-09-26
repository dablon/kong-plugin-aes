return {
  name = "aes-crypto",
  fields = {
    { config = {
        type = "record",
        fields = {
          { encryption_key = { type = "string", required = true } },
        },
      },
    },
  },
}