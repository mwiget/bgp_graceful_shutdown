#!/bin/bash
#
if [ -z "$1" ]; then
    echo "need network name as argument"
    exit 1
fi

netid=$(docker network ls|grep $1|cut -d' ' -f1)
if [ -z "$netid" ]; then
    echo "network $1 not found"
    exit 1
fi
echo "Disabling eth tx checksum offload on network $1"
net="br-$netid"
echo "mgmt net $net has id $netid"
sudo ethtool --offload $net tx off
