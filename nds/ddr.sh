#!/bin/bash

# Запрашиваем данные для прокси по очереди
read -p "Enter PROXY IP: " PROXY_IP
read -p "Enter PROXY PORT: " PROXY_PORT
read -p "Enter PROXY LOGIN: " PROXY_USERNAME
read -p "Enter PROXY PASSWORD: " PROXY_PASSWORD

PROXY_TYPE="socks5"

# Проверка, что все поля заполнены
if [[ -z "$PROXY_IP" || -z "$PROXY_PORT" || -z "$PROXY_USERNAME" || -z "$PROXY_PASSWORD" ]]; then
  echo "All fields must be filled. Please try again."
  exit 1
fi

# Ввод API ключа и приватного ключа
read -p "Enter your API key: " API_KEY
read -p "Enter your Private Key: " PRIVATE_KEY



# Создание конфигурационного файла для redsocks
cat <<EOL > redsocks.conf
base {
    log_debug = off;
    log_info = off;
    log = "stderr";
    daemon = off;
    redirector = iptables;
}
redsocks {
    local_ip = 127.0.0.1;
    local_port = 12345;
    
    ip = $PROXY_IP;
    port = $PROXY_PORT;
    type = $PROXY_TYPE;
    login = "$PROXY_USERNAME";
    password = "$PROXY_PASSWORD";
}
EOL

# Проверка существующих контейнеров с таким именем
function get_next_container_name() {
    local base_name="dria-$1"
    echo "$base_name"
}
CONTAINER_NAME=$(get_next_container_name "$PROXY_IP")

# Create the entrypoint script
cat <<EOL > entrypoint.sh
#!/bin/bash
set -e
echo "[*] Starting proxy setup..."
echo "[*] Testing proxy connection..."
nc -zv $PROXY_IP $PROXY_PORT || {
    echo "[ERROR] Cannot connect to proxy server!"
    exit 1
}
echo "[*] Flushing existing iptables rules..."
iptables -t nat -F
iptables -t filter -F
iptables -t mangle -F
iptables -t nat -X REDSOCKS 2>/dev/null || true
echo "[*] Creating REDSOCKS chain..."
iptables -t nat -N REDSOCKS
echo "[*] Setting up exclusion rules..."
iptables -t nat -A REDSOCKS -d $PROXY_IP -j RETURN
iptables -t nat -A REDSOCKS -d 0.0.0.0/8 -j RETURN
iptables -t nat -A REDSOCKS -d 10.0.0.0/8 -j RETURN
iptables -t nat -A REDSOCKS -d 127.0.0.0/8 -j RETURN
iptables -t nat -A REDSOCKS -d 169.254.0.0/16 -j RETURN
iptables -t nat -A REDSOCKS -d 172.16.0.0/12 -j RETURN
iptables -t nat -A REDSOCKS -d 192.168.0.0/16 -j RETURN
iptables -t nat -A REDSOCKS -d 224.0.0.0/4 -j RETURN
iptables -t nat -A REDSOCKS -d 240.0.0.0/4 -j RETURN
echo "[*] Setting up redirect rules..."
iptables -t nat -A REDSOCKS -p tcp -j REDIRECT --to-ports 12345
echo "[*] Applying REDSOCKS chain..."
iptables -t nat -A OUTPUT -o lo -j RETURN
iptables -t nat -A OUTPUT -p tcp -j REDSOCKS
echo "[*] Starting redsocks..."
redsocks -c /etc/redsocks.conf &
sleep 5
echo "[*] Verifying that redsocks is running..."
if ! pgrep redsocks > /dev/null; then
    echo "[ERROR] Redsocks failed to start!"
    exit 1
fi
echo "[*] Executing user command..."
exec "\$@"
EOL

cat <<EOL > Dockerfile
FROM ubuntu:22.04 as builder
# Install build dependencies
RUN apt-get update && apt-get install -y git gcc make libevent-dev && rm -rf /var/lib/apt/lists/*
# Clone and build redsocks
RUN git clone --branch release-0.5 --single-branch https://github.com/darkk/redsocks.git
WORKDIR /redsocks
RUN make
FROM ubuntu:22.04
# Install runtime dependencies and debugging tools
RUN apt-get update && apt-get install -y iptables kmod curl libevent-2.1-7 libevent-core-2.1-7 libevent-extra-2.1-7 wget unzip nano git \
    libevent-openssl-2.1-7 libevent-pthreads-2.1-7 netcat tcpdump iproute2 net-tools && rm -rf /var/lib/apt/lists/*
# Create log directory
RUN mkdir -p /var/log && touch /var/log/redsocks.log
# Copy built redsocks from builder
COPY --from=builder /redsocks/redsocks /usr/local/bin/
EOL

cat <<EOL >> Dockerfile
# Configure redsocks
COPY redsocks.conf /etc/redsocks.conf
# Setup entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
# Set entrypoint to the script
ENTRYPOINT ["/entrypoint.sh"]
RUN wget https://github.com/firstbatchxyz/dkn-compute-launcher/releases/latest/download/dkn-compute-launcher-linux-amd64.zip -P /opt
RUN unzip /opt/dkn-compute-launcher-linux-amd64.zip -d /opt

RUN sed -i 's/^DKN_WALLET_SECRET_KEY=.*$/DKN_WALLET_SECRET_KEY=$PRIVATE_KEY/' /opt/dkn-compute-node/.env
RUN sed -i 's/^OPENAI_API_KEY=.*$/OPENAI_API_KEY=$API_KEY/' /opt/dkn-compute-node/.env

RUN sed -i 's/^DKN_MODELS=.*$/DKN_MODELS=gpt-4-turbo,gpt-4o,gpt-4o-mini,o1-mini,o1-preview/' /opt/dkn-compute-node/.env
CMD yes "" | head -n 3 | /opt/dkn-compute-node/dkn-compute-launcher

EOL


docker build -t $CONTAINER_NAME .
docker run --privileged --cap-add=NET_ADMIN -d --name $CONTAINER_NAME $CONTAINER_NAME 
