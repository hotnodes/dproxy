#!/bin/bash


if [ $(id -u) != 0 ]; then
  echo "Run script from user root. Your user is ${USER}"
  exit 1
fi

if ! command -v curl &>/dev/null; then
 echo "Installing curl"
 apt update -qq && apt install -qq curl
fi

read -p "Enter your username: " PROXY_USER

echo "Installing required packages..."
apt update -yqq && apt install -yqq --no-suggestions dante-server gawk pwgen curl

PROXY_PUBLIC_INTERFACE=$(cat /proc/net/arp | tail -1 |awk '{print $NF}')
PROXY_IP=$(curl -s ifconfig.me)
PROXY_LISTEN_PORT='18080'
PROXY_PASSWORD=$(pwgen -1sBv 18)
PROXY_CREDENTIALS_PATH="${HOME}/.proxy-credentials"

echo "Setting up proxy..."
echo "
internal: ${PROXY_PUBLIC_INTERFACE} port = ${PROXY_LISTEN_PORT}
external: ${PROXY_PUBLIC_INTERFACE}

socksmethod: username

user.unprivileged: nobody
user.privileged: root

client pass {
from: 0.0.0.0/0 to: 0.0.0.0/0
log: error
}

socks pass {
from: 0.0.0.0/0 to: 0.0.0.0/0
command: connect
log: error
socksmethod: username
}" > /etc/danted.conf

useradd -r -s /bin/false ${PROXY_USER} -p ${PROXY_PASSWORD}

systemctl -q restart danted.service

echo "#########################################"
echo "Proxy user:password -> ${PROXY_USER}:${PROXY_PASSWORD}" >> ${PROXY_CREDENTIALS_PATH}
echo "Your proxy is ready."
echo "Proxy credentials saved in ${PROXY_CREDENTIALS_PATH}"
echo "Connect to proxy: ${PROXY_USER}:${PROXY_PASSWORD}@${PROXY_IP}:${LISTEN_PORT}"
echo "#########################################"

