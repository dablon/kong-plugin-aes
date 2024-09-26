FROM kong:latest

# Switch to root to install build dependencies
USER root

# Install build dependencies required by the plugin
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        git \
        make \
        gcc \
        g++ \
        libc-dev \
        libssl-dev && \
    rm -rf /var/lib/apt/lists/*

# Install the correct OpenSSL Lua module
RUN luarocks install openssl

# Copy the plugin code into the container
COPY . /tmp/kong-plugin-aes
# RUN luarocks install /tmp/kong-plugin-aes/aes-encryption-1.0-1.rockspec

# Navigate to the plugin directory
WORKDIR /tmp/kong-plugin-aes

# Fix: Update the rockspec to use 'openssl' instead of 'lua-openssl'
RUN sed -i 's/lua-openssl/openssl/g' aes-encryption-1.0-1.rockspec

# Install the plugin via LuaRocks using make (builds from local source)
RUN luarocks make aes-encryption-1.0-1.rockspec

# Clean up build dependencies to reduce image size
RUN apt-get purge -y --auto-remove \
        git \
        make \
        gcc \
        g++ \
        libc-dev \
        libssl-dev && \
    rm -rf /tmp/kong-plugin-aes

# Switch back to the 'kong' user for security
USER kong

# Set the working directory back to Kong's default
WORKDIR /usr/local/kong