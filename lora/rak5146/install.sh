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

SX1303_HAL_URL="https://github.com/Lora-net/sx1302_hal/archive/V2.1.0.tar.gz"
wget $SX1303_HAL_URL -O ./rak5146.tar.gz

tar -zxvf ./rak5146.tar.gz

sleep 1
mv sx1302_hal-2.1.0 sx1303_hal
pushd sx1303_hal
make clean
cp ../loragw_stts751.c libloragw/src/loragw_stts751.c -f
cp ../test_loragw_gps_uart.c libloragw/tst/test_loragw_gps.c -f
cp ../test_loragw_gps_i2c.c libloragw/tst/test_loragw_gps_i2c.c -f

#mkdir -p packet_forwarder/lora_pkt_fwd/
#cp ../reset_lgw.sh packet_forwarder/lora_pkt_fwd/reset_lgw.sh -f

cp ../lora_pkt_fwd.c packet_forwarder/src/lora_pkt_fwd.c
make
rm packet_forwarder/lora_pkt_fwd/obj/* -f
popd

if [ -d $INSTALL_DIR/packet_forwarder ]; then
    rm -rf $INSTALL_DIR/packet_forwarder/
fi
cp $INSTALL_DIR/sx1303_hal/packet_forwarder $INSTALL_DIR/ -rf
cp $INSTALL_DIR/sx1303_hal/libloragw $INSTALL_DIR/lora_gateway -rf
if [ -f $SCRIPT_DIR/../../lte/lte_test ]; then
	cp $SCRIPT_DIR/../../lte/lte_test $INSTALL_DIR/lora_gateway/
	cp $SCRIPT_DIR/reset_lgw.sh $INSTALL_DIR/lora_gateway/
fi
mv $INSTALL_DIR/packet_forwarder/lora_pkt_fwd $INSTALL_DIR/packet_forwarder/lora_pkt_fwd_bak
mkdir -p $INSTALL_DIR/packet_forwarder/lora_pkt_fwd
mv $INSTALL_DIR/packet_forwarder/lora_pkt_fwd_bak $INSTALL_DIR/packet_forwarder/lora_pkt_fwd/lora_pkt_fwd

if [ -d global_conf ]; then
	cp global_conf $INSTALL_DIR/packet_forwarder/lora_pkt_fwd/ -rf
	cp global_conf/global_conf.in_865_867.json $INSTALL_DIR/packet_forwarder/lora_pkt_fwd/global_conf.json
	sed -i "s/^.*server_address.*$/\t\"server_address\": \"10.1.1.14\",/" $INSTALL_DIR/packet_forwarder/lora_pkt_fwd/global_conf.json
fi

cp reset_lgw.sh $INSTALL_DIR/packet_forwarder/lora_pkt_fwd/reset_lgw.sh
rm -f $INSTALL_DIR/packet_forwarder/lora_pkt_fwd/local_conf.json
