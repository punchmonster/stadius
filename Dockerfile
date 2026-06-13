FROM openresty/openresty:bookworm

RUN apt-get update && apt-get install -y \
    luarocks \
    build-essential \
    git \
    libssl-dev \
    libreadline-dev \
    libpcre3-dev \
    unzip \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Make sure luarocks can write config
RUN mkdir -p /root/.luarocks

# IMPORTANT: avoid config command entirely
ENV LUAROCKS_CONFIG=/root/.luarocks/config-5.1.lua

# Install dependencies first
RUN luarocks install luasocket \
 && luarocks install luasec

# Install lapis
RUN luarocks install lapis

WORKDIR /app

EXPOSE 8080

CMD ["bash"]
