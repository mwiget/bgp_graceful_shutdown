#!/bin/ash

echo "disabling checksum offload"
ethtool --offload eth0 rx off tx off

mkdir -p /usr/local/etc/exabgp
exabgp --fi > /usr/local/etc/exabgp/exabgp.env
mkfifo /var/run/exabgp.in && mkfifo /var/run/exabgp.out
chmod 600 /var/run/exabgp.*

while true; do
  env exabgp.tcp.bind=0.0.0.0 exabgp.daemon.user=root exabgp /etc/exabgp/exabgp.conf
  echo "restarting in 5 seconds ..."
  sleep 5
done
