#!/bin/bash

# Stop on the first sign of trouble
set -e

if [ $UID != 0 ]; then
    echo "ERROR: Operation not permitted. Forgot sudo?"
    exit 1
fi

SCRIPT_DIR=$(pwd)

# Request gateway configuration data
# There are two ways to do it, manually specify everything
# or rely on the gateway EUI and retrieve settings files from remote (recommended)
echo "Gateway configuration:"

# Install LoRaWAN packet forwarder repositories
INSTALL_DIR="./"
if [ ! -d "$INSTALL_DIR" ]; then mkdir $INSTALL_DIR; fi
pushd $INSTALL_DIR

# Build LoRa gateway app

if [ ! -d $SCRIPT_DIR/../lora_gateway ]; then
    git clone https://github.com/Lora-net/lora_gateway.git
else
    cp $SCRIPT_DIR/../lora_gateway . -rf
fi

pushd lora_gateway

cp $SCRIPT_DIR/library.cfg ./libloragw/library.cfg
#cp $SCRIPT_DIR/loragw_spi.native.c ./libloragw/src/loragw_spi.native.c
make

popd

# Build packet forwarder

if [ ! -d $SCRIPT_DIR/../packet_forwarder ]; then
    git clone https://github.com/Lora-net/packet_forwarder.git
else
    cp $SCRIPT_DIR/../packet_forwarder . -rf
fi

pushd packet_forwarder

cp $SCRIPT_DIR/lora_pkt_fwd.c ./lora_pkt_fwd/src/lora_pkt_fwd.c

make
rm lora_pkt_fwd/obj/* -f
popd

pushd lora_gateway
make clean
popd

cp global_conf $INSTALL_DIR/packet_forwarder/lora_pkt_fwd/ -rf
cp global_conf/global_conf.in_865_867.json $INSTALL_DIR/packet_forwarder/lora_pkt_fwd/global_conf.json
sed -i "s/^.*server_address.*$/\t\"server_address\": \"10.1.1.14\",/" $INSTALL_DIR/packet_forwarder/lora_pkt_fwd/global_conf.json
rm -f $INSTALL_DIR/packet_forwarder/lora_pkt_fwd/local_conf.json

