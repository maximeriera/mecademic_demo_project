#!/usr/bin/env bash
set -euo pipefail

# ================= Configuration =================
STATIC_IP="192.168.0.50/24"
STATIC_IP_RAW="192.168.0.50"
GATEWAY_IP="192.168.0.1"
UPSTREAM_DNS_1="1.1.1.1"
UPSTREAM_DNS_2="8.8.8.8"

CUSTOM_DOMAIN="mecademo.link"
REPO_URL="https://github.com/maximeriera/mecademic_demo_app"

# Identify the target user and directories
TARGET_USER="${SUDO_USER:-$USER}"
TARGET_HOME=$(getent passwd "$TARGET_USER" | cut -d: -f6)
TARGET_DIR="${TARGET_HOME}/demo_ws"
PIHOLE_DIR="${TARGET_HOME}/pihole"
# =================================================

if [ "$EUID" -ne 0 ]; then
  echo "Error: This script must be run as root. Run with: sudo $0" >&2
  exit 1
fi

echo "=== 1. Detecting Primary Network Interface ==="
PRIMARY_IFACE=$(ip -4 route show default 2>/dev/null | awk '{print $5}' | head -n1 || true)
if [ -z "$PRIMARY_IFACE" ]; then
  PRIMARY_IFACE=$(ip -o link show | awk -F': ' '$2 !~ /^(lo|docker|br-|veth)/ {print $2}' | head -n1)
fi
echo "Using network interface: ${PRIMARY_IFACE}"

echo "=== 2. Updating System & Installing Prerequisites ==="
# Temporarily write a reliable resolv.conf during bootstrap so apt/curl never stall
echo -e "nameserver ${UPSTREAM_DNS_1}\nnameserver ${UPSTREAM_DNS_2}" > /etc/resolv.conf

apt-get update
apt-get install -y ca-certificates curl gnupg lsb-release git dnsutils

echo "=== 3. Installing Official Docker & Compose Plugin ==="
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

UBUNTU_CODENAME=$(lsb_release -cs)
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu ${UBUNTU_CODENAME} stable" \
  > /etc/apt/sources.list.d/docker.list

apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Configure Docker daemon upstream DNS so containers don't inherit local 127.0.0.1
mkdir -p /etc/docker
cat <<EOF > /etc/docker/daemon.json
{
  "dns": ["${UPSTREAM_DNS_1}", "${UPSTREAM_DNS_2}"]
}
EOF

systemctl enable --now docker
systemctl restart docker
usermod -aG docker "$TARGET_USER"

echo "=== 4. Freeing Port 53 (systemd-resolved) ==="
# Stop systemd-resolved from listening on 127.0.0.53:53
mkdir -p /etc/systemd/resolved.conf.d/
cat <<EOF > /etc/systemd/resolved.conf.d/pihole-port53.conf
[Resolve]
DNSStubListener=no
EOF
systemctl restart systemd-resolved

echo "=== 5. Deploying Pi-hole & Injecting Custom Local DNS ==="
mkdir -p "${PIHOLE_DIR}/etc-pihole" "${PIHOLE_DIR}/etc-dnsmasq.d"

# 1. Custom Local DNS Record
echo "${STATIC_IP_RAW} ${CUSTOM_DOMAIN}" > "${PIHOLE_DIR}/etc-pihole/custom.list"

# 2. Add dnsmasq rule to ensure fast local domain resolution and fix packet size timeouts
cat <<EOF > "${PIHOLE_DIR}/etc-dnsmasq.d/02-custom.conf"
address=/${CUSTOM_DOMAIN}/${STATIC_IP_RAW}
edns-packet-max=1232
EOF

# 3. Disable rate limiting on Pi-hole to prevent 127.0.0.1 lookups from being throttled
cat <<EOF > "${PIHOLE_DIR}/etc-pihole/pihole-FTL.conf"
RATE_LIMIT=0/0
EOF

# 4. Generate docker-compose.yml
cat <<EOF > "${PIHOLE_DIR}/docker-compose.yml"
services:
  pihole:
    container_name: pihole
    image: pihole/pihole:latest
    network_mode: host
    environment:
      TZ: '$(cat /etc/timezone 2>/dev/null || echo "UTC")'
      FTLCONF_LOCAL_IPV4: '${STATIC_IP_RAW}'
      PIHOLE_DNS_: '${UPSTREAM_DNS_1};${UPSTREAM_DNS_2}'
      DNSMASQ_LISTENING: 'all'
    volumes:
      - './etc-pihole:/etc/pihole'
      - './etc-dnsmasq.d:/etc/dnsmasq.d'
    restart: unless-stopped
EOF

chown -R "${TARGET_USER}:${TARGET_USER}" "${PIHOLE_DIR}"

# Launch Pi-hole container
docker compose -f "${PIHOLE_DIR}/docker-compose.yml" up -d

echo "Waiting for Pi-hole to initialize..."
until docker exec pihole pihole status &>/dev/null; do
  sleep 2
done

echo "=== 6. Configuring Static IP & System DNS Resolution ==="
# Backup old Netplan files
mkdir -p /etc/netplan/backup
cp /etc/netplan/*.yaml /etc/netplan/backup/ 2>/dev/null || true

# Write static IP Netplan (points host DNS to local Pi-hole first, with public fallback)
cat <<EOF > /etc/netplan/01-static-pihole.yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    ${PRIMARY_IFACE}:
      dhcp4: no
      addresses:
        - ${STATIC_IP}
      routes:
        - to: default
          via: ${GATEWAY_IP}
      nameservers:
        addresses: [127.0.0.1, ${UPSTREAM_DNS_1}]
EOF

chmod 600 /etc/netplan/01-static-pihole.yaml
netplan generate
netplan apply

# Re-link /etc/resolv.conf to the dynamic systemd-resolved output file
ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf

echo "=== 7. Cloning Demo Repository ==="
if [ -d "$TARGET_DIR" ]; then
  echo "Directory ${TARGET_DIR} already exists. Skipping git clone."
else
  sudo -u "$TARGET_USER" git clone "$REPO_URL" "$TARGET_DIR"
fi

echo "=== 8. Verifying DNS Operations ==="
echo "Testing local resolution (${CUSTOM_DOMAIN}):"
nslookup "${CUSTOM_DOMAIN}" 127.0.0.1 || true

echo "Testing internet resolution (google.com):"
nslookup google.com 127.0.0.1 || true

echo "=========================================================="
echo " Setup Finished Successfully!"
echo "- Pi-hole Admin: http://${STATIC_IP_RAW}/admin"
echo "- Local Record:  ${CUSTOM_DOMAIN} -> ${STATIC_IP_RAW}"
echo "- To set Pi-hole password: docker exec -it pihole pihole -a -p"
echo "=========================================================="
