#!/bin/bash
set -e

CHAINID_1=$1
CHAINID_2=$2

# Load shell variables
. ./variables.sh

### Configure the clients and connection
echo "Initiating connection handshake..."
$HERMES_BINARY -c $CONFIG_DIR create connection $CHAINID_1 $CHAINID_2

sleep 2
