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
        libssl-dev \
        tree && \
    rm -rf /var/lib/apt/lists/*

# Install the correct OpenSSL Lua module
RUN luarocks install openssl

# Copy the plugin code into the container
COPY . /tmp/kong-plugin-aes-crypto

# Navigate to the plugin directory
WORKDIR /tmp/kong-plugin-aes-crypto

# Print out the directory structure
RUN echo "Directory structure:" && tree

# Update the rockspec to use 'openssl' instead of 'lua-openssl'
RUN find . -type f -name "*.rockspec" -exec sed -i 's/lua-openssl/openssl/g' {} +

# Find and update the plugin name in all relevant files
RUN find . -type f -name "*.lua" -exec sed -i 's/aes-crypto/aes-encryption/g' {} +
RUN find . -type f -name "*.rockspec" -exec sed -i 's/aes-crypto/aes-encryption/g' {} +

# Rename the rockspec file if it exists
RUN for f in *.rockspec; do \
    new_name=$(echo "$f" | sed 's/aes-crypto/aes-encryption/'); \
    if [ "$f" != "$new_name" ]; then \
        mv "$f" "$new_name"; \
    fi; \
done

# List the contents of the current directory
RUN ls -la

# Install the plugin via LuaRocks
RUN luarocks make *.rockspec

# Print out the installed rocks
RUN luarocks list

# Clean up build dependencies to reduce image size
RUN apt-get purge -y --auto-remove \
        git \
        make \
        gcc \
        g++ \
        libc-dev \
        libssl-dev \
        tree && \
    rm -rf /tmp/kong-plugin-aes-crypto

# Switch back to the 'kong' user for security
USER kong

# Set the working directory back to Kong's default
WORKDIR /usr/local/kong

# Ensure the custom plugin is loaded
ENV KONG_PLUGINS=bundled,aes-encryption

# Verify the plugin is installed and print Kong version
RUN kong version && luarocks list