#!/bin/bash
set -e

# Проверка прав root
if [ "$(id -u)" -ne 0 ]; then
    echo "Please run as root"
    exit 1
fi

# Проверка аргументов
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

# Удаление существующего интерфейса
if ip link show $TUNNEL_IF >/dev/null 2>&1; then
    echo "Removing existing interface $TUNNEL_IF"
    ip link set $TUNNEL_IF down
    ip tunnel del $TUNNEL_IF
fi

# Создание GRE туннеля
echo "Creating GRE tunnel: $TUNNEL_IF"
ip tunnel add $TUNNEL_IF mode gre \
    remote $REMOTE_IP \
    local $LOCAL_IP \
    ttl 255

# Настройка адресации
echo "IP: $LOCAL_TUNNEL_IP -> $REMOTE_TUNNEL_IP"
ip addr add $LOCAL_TUNNEL_IP dev $TUNNEL_IF
ip route add $REMOTE_TUNNEL_IP dev $TUNNEL_IF

# Активация интерфейса
echo "Starting tunnel $TUNNEL_IF"
ip link set $TUNNEL_IF up mtu 1476

# Маршрутизация
echo "Routing $DEST_NETWORK via $REMOTE_TUNNEL_IP"
ip route add $DEST_NETWORK via $REMOTE_TUNNEL_IP dev $TUNNEL_IF

# Форвардинг
sysctl -w net.ipv4.ip_forward=1 >/dev/null

# Фаервол
iptables -A INPUT -p gre -j ACCEPT
iptables -A FORWARD -i $TUNNEL_IF -j ACCEPT

echo "GRE tunnel $TUNNEL_IF configured!"
