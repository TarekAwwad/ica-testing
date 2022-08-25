#!/bin/bash


display_usage() {
	echo "\nMissing $1 parameter. Please check if all parameters were specified."
	echo "\nUsage: $0 [BINARY] [CHAIN_ID] [CHAIN_DIR] <RPC_PORT> <DENOM> <API_PORT>"
	exit 1
}

KEYRING=--keyring-backend="test"
SILENT=1

BINARY=$1
CHAINID=$2
CHAINDIR=$3
RPCPORT=${4:-56657}
DENOM=${5:-utki}
APIPORT=${6:-5317}
UPGRADE_NAME=${7:-v4}

RPCNODE="http://localhost:"$RPCPORT

# Checks args
args=(BINARY CHAINID CHAINDIR RPCPORT DENOM APIPORT)
for argName in "${args[@]}"; do
	argValue=${!argName}
	if [ -z $argValue ]; then
	  display_usage $argName;
	  exit
	fi
	echo $argName=$argValue
done

HOME_DIR=./$CHAINDIR/$CHAINID
echo $HOME_DIR

# Global infos
$BINARY version


# Upgrade to v4
echo '---- Upgrade to v4'

currentBlock=`curl localhost:$APIPORT/blocks/latest | jq -r .block.header.height`
echo 'currentBlock='$currentBlock

upgradeBlock=$((currentBlock+25))
echo 'upgradeBlock='$upgradeBlock


$BINARY tx gov submit-proposal software-upgrade $UPGRADE_NAME --upgrade-height $upgradeBlock --deposit 10000000$DENOM --title $UPGRADE_NAME --description test --from wallet-0  --chain-id $CHAINID --home $HOME_DIR --node $RPCNODE --keyring-backend=test --broadcast-mode=block --output=json --yes

$BINARY tx gov vote 1 yes --from validator --chain-id $CHAINID --home $HOME_DIR --node $RPCNODE --keyring-backend=test --broadcast-mode=block --output=json --yes

curl http://localhost:$APIPORT/gov/proposals/1 | jq

echo "to upgrade: ./build/kid start --home $HOME_DIR"
