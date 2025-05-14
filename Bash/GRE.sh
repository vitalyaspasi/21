#!/bin/bash
set -e

if [ "$(id -u)" -ne 0 ]; then
    echo "Please run as root"
    exit 1
fi

if [ $# -ne 5 ]; then
    echo "Usage: $0 <local_ip> <remote_ip> <local_tunnel_ip> <remote_tunnel_ip> <dest_network>"
    echo "Example: $0 203.0.113.1 198.51.100.2 10.0.0.1 10.0.0.2 192.168.2.0/24"
    exit 1
fi

# Параметры
LOCAL_IP=$1
REMOTE_IP=$2
LOCAL_TUNNEL_IP=$3
REMOTE_TUNNEL_IP=$4
DEST_NETWORK=$5
TUNNEL_IF="gre1"
CONFIG_FILE="/etc/systemd/network/90-gre-tunnel.network"

# 1. Создаем systemd network config
echo "Creating persistent network configuration..."
cat > $CONFIG_FILE <<EOF
[Match]
Name=$TUNNEL_IF

[Network]
Address=$LOCAL_TUNNEL_IP/32
IPForward=yes

[Route]
Destination=$DEST_NETWORK
Gateway=$REMOTE_TUNNEL_IP

[Tunnel]
Local=$LOCAL_IP
Remote=$REMOTE_IP
Mode=gre
TTL=255
EOF

echo "Restarting network services..."
systemctl restart systemd-networkd

echo "GRE tunnel configured to survive reboots!"
echo "Check status: networkctl list $TUNNEL_IF"
