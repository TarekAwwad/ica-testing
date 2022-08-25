#!/bin/bash
set -e

CHAINID_1=$1
CHAINID_2=$2

# Load shell variables
. ./variables.sh

### Sleep is needed otherwise the relayer crashes when trying to init
sleep 1s
### Restore Keys
$HERMES_BINARY -c $CONFIG_DIR keys restore $CHAINID_1 -m "donate route animal guide similar strategy canyon audit common verify rebuild mention genius arrange hawk machine frame move purse rug typical squeeze confirm record"
sleep 5s

$HERMES_BINARY -c $CONFIG_DIR keys restore $CHAINID_2 -m "donate route animal guide similar strategy canyon audit common verify rebuild mention genius arrange hawk machine frame move purse rug typical squeeze confirm record"
sleep 5s
