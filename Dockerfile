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
    imagemagick \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /root/.luarocks
ENV LUAROCKS_CONFIG=/root/.luarocks/config-5.1.lua

RUN luarocks install luasocket \
 && luarocks install luasec

RUN luarocks install lapis

WORKDIR /app

# Bake the code into the image
COPY . /app

# Ensure log directory exists
RUN mkdir -p /app/logs

# Compile the nginx config for production (lua_code_cache on, daemon off)
RUN lapis build production

EXPOSE 8080

CMD ["openresty", "-c", "/app/nginx.conf.compiled", "-p", "/app"]
