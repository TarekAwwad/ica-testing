#!/bin/bash

display_usage() {
	echo "\nMissing $1 parameter. Please check if all parameters were specified."
	echo "\nUsage: $0 [BINARY] [CHAIN_ID] [CHAIN_DIR] <RPC_PORT] <P2P_PORT> <PROFILING_PORT> <GRPC_PORT> <DENOM> <API_PORT>"
	echo "\nExample: $0 $BINARY test-chain-id ./data\n"
	exit 1
}

KEYRING=--keyring-backend="test"
SILENT=1

redirect() {
  if [ "$SILENT" -eq 1 ]; then
		echo "Launching: $@"
    "$@" > /dev/null 2>&1
  else
    "$@"
  fi
}

BINARY=$1
CHAINID=$2
CHAINDIR=$3
RPCPORT=${4:-56657}
P2PPORT=${5:-56656}
PROFPORT=${6:-6565}
GRPCPORT=${7:-9595}
DENOM=${8:-utki}
APIPORT=${9:-5317}


VAL_MNEMONIC_1="process sock impose term betray road lemon edit bounce cabin leaf kitchen noble venue bomb decrease capable alcohol question tackle cup turkey oil wave"
WALLET_MNEMONIC_0="cover primary bus faith jeans mimic water donkey defense mad sphere pony scrap hurdle polar battle gift loop family harbor asthma enforce fade soda"
WALLET_MNEMONIC_1="rapid phone market team lava carbon oil couple protect group kite enter attitude ramp honey cheese sketch eye album whip space space toss child"
WALLET_MNEMONIC_2="clog mango master camera ordinary someone metal scorpion cause job save october clay delay inquiry pole skill know mail pond firm silver skate cinnamon"
WALLET_MNEMONIC_3="angle cruel virtual depth caught vessel siren alien analyst rate bulb three unable market judge shuffle thunder force shield device obtain subway proud text"
WALLET_MNEMONIC_4="sister palace sauce embrace kidney pipe begin place raven guide busy picnic hawk tail much only impulse envelope bottom ask ring mansion glad helmet"
RLY_MNEMONIC_1="donate route animal guide similar strategy canyon audit common verify rebuild mention genius arrange hawk machine frame move purse rug typical squeeze confirm record"
RLY_MNEMONIC_2="shoulder property shrug render lesson sample spread enhance voice problem between copy candy rack city hub raw clerk honey roof volume record cousin rather"


# Checks args
args=(BINARY CHAINID CHAINDIR RPCPORT P2PPORT PROFPORT GRPCPORT DENOM APIPORT)
for argName in "${args[@]}"; do
	argValue=${!argName}
	if [ -z $argValue ]; then
	  display_usage $argName;
	  exit
	fi
	echo $argName=$argValue
done

# Alert for deletion
HOME_DIR=./$CHAINDIR/$CHAINID
if [[ -d $HOME_DIR ]]; then
  echo "$HOME_DIR already exists, please delete it manually (rm -rf $HOME_DIR)"
	exit 1
fi

# Continue?
read -p "Continue? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
	exit 1
fi

# stop previous runs
killall $BINARY &> /dev/null

echo "Creating $BINARY instance: home=$CHAINDIR | chain-id=$CHAINID | p2p=:$P2PPORT | rpc=:$RPCPORT | profiling=:$PROFPORT | grpc=:$GRPCPORT | api=:$APIPORT"

# Add dir for chain, exit if error
if ! mkdir -p $HOME_DIR 2>/dev/null; then
    echo "Failed to create chain folder. Aborting..."
    exit 1
fi

# Build genesis file incl account for passed address
coins="1000000000000"$DENOM
delegate="100000000000"$DENOM

redirect $BINARY --home $HOME_DIR --chain-id $CHAINID init $CHAINID
sleep 1


echo $VAL_MNEMONIC_1 | $BINARY --home $HOME_DIR keys add validator $KEYRING --recover
redirect $BINARY --home $HOME_DIR add-genesis-account $($BINARY --home $HOME_DIR keys $KEYRING show validator -a) $coins
sleep 1

echo $WALLET_MNEMONIC_0 | $BINARY --home $HOME_DIR keys add wallet-0 $KEYRING --recover
redirect $BINARY --home $HOME_DIR add-genesis-account $($BINARY --home $HOME_DIR keys $KEYRING show  wallet-0 -a) $coins
sleep 1

echo $WALLET_MNEMONIC_1 | $BINARY --home $HOME_DIR keys add wallet-1 $KEYRING --recover
redirect $BINARY --home $HOME_DIR add-genesis-account $($BINARY --home $HOME_DIR keys $KEYRING show  wallet-1 -a) $coins
sleep 1

echo $WALLET_MNEMONIC_2 | $BINARY --home $HOME_DIR keys add wallet-2 $KEYRING --recover
redirect $BINARY --home $HOME_DIR add-genesis-account $($BINARY --home $HOME_DIR keys $KEYRING show  wallet-2 -a) $coins
sleep 1

echo $WALLET_MNEMONIC_3 | $BINARY --home $HOME_DIR keys add wallet-3 $KEYRING --recover
redirect $BINARY --home $HOME_DIR add-genesis-account $($BINARY --home $HOME_DIR keys $KEYRING show  wallet-3 -a) $coins
sleep 1

echo $WALLET_MNEMONIC_4 | $BINARY --home $HOME_DIR keys add wallet-4 $KEYRING --recover
redirect $BINARY --home $HOME_DIR add-genesis-account $($BINARY --home $HOME_DIR keys $KEYRING show  wallet-4 -a) $coins
sleep 1

echo $RLY_MNEMONIC_1 | $BINARY --home $HOME_DIR keys add rly-1 $KEYRING --recover
redirect $BINARY --home $HOME_DIR add-genesis-account $($BINARY --home $HOME_DIR keys $KEYRING show  rly-1 -a) $coins
sleep 1

echo $RLY_MNEMONIC_2 | $BINARY --home $HOME_DIR keys add rly-2 $KEYRING --recover
redirect $BINARY --home $HOME_DIR add-genesis-account $($BINARY --home $HOME_DIR keys $KEYRING show  rly-2 -a) $coins
sleep 1

# Initial delegation
redirect $BINARY --home $HOME_DIR gentx validator $delegate $KEYRING --chain-id $CHAINID
sleep 1
redirect $BINARY --home $HOME_DIR collect-gentxs
sleep 1

# Check platform
platform='unknown'
unamestr=`uname`
if [ "$unamestr" = 'Linux' ]; then
   platform='linux'
fi

# Set proper defaults and change ports (use a different sed for Mac or Linux)
echo "Change settings in config.toml file..."
if [ $platform = 'linux' ]; then
	sed -i "s/\"stake\"/\"$DENOM\"/g" $HOME_DIR/config/genesis.json
	sed -i 's#"tcp://127.0.0.1:26657"#"tcp://0.0.0.0:'"$RPCPORT"'"#g' $HOME_DIR/config/config.toml
	sed -i 's#"tcp://0.0.0.0:26656"#"tcp://0.0.0.0:'"$P2PPORT"'"#g' $HOME_DIR/config/config.toml
	sed -i 's#"localhost:6060"#"localhost:'"$PROFPORT"'"#g' $HOME_DIR/config/config.toml
	sed -i 's/timeout_commit = "5s"/timeout_commit = "1s"/g' $HOME_DIR/config/config.toml
	sed -i 's/timeout_propose = "3s"/timeout_propose = "1s"/g' $HOME_DIR/config/config.toml
	sed -i 's/index_all_keys = false/index_all_keys = true/g' $HOME_DIR/config/config.toml
	sed -i 's/pruning = "default"/pruning = "nothing"/g'	$HOME_DIR/config/app.toml
	sed -i '138s/enable = true/enable = false/g'       $HOME_DIR/config/app.toml
	sed -i '175s/enable = true/enable = false/g'       $HOME_DIR/config/app.toml
	sed -i 's#"0.0.0.0:9090"#"0.0.0.0:'"$GRPCPORT"'"#g' $HOME_DIR/config/app.toml
	if ! [ -z "$APIPORT" ]; then
		sed -i '108s/enable = false/enable = true/g'	$HOME_DIR/config/app.toml
		sed -i 's#"tcp://0.0.0.0:1317"#"tcp://localhost:'"$APIPORT"'"#g' $HOME_DIR/config/app.toml
	fi
else
	sed -i '' "s/\"stake\"/\"$DENOM\"/g" $HOME_DIR/config/genesis.json
	sed -i '' 's#"tcp://127.0.0.1:26657"#"tcp://0.0.0.0:'"$RPCPORT"'"#g' $HOME_DIR/config/config.toml
	sed -i '' 's#"tcp://0.0.0.0:26656"#"tcp://0.0.0.0:'"$P2PPORT"'"#g' $HOME_DIR/config/config.toml
	sed -i '' 's#"localhost:6060"#"localhost:'"$PROFPORT"'"#g' $HOME_DIR/config/config.toml
	sed -i '' 's/timeout_commit = "5s"/timeout_commit = "1s"/g' $HOME_DIR/config/config.toml
	sed -i '' 's/timeout_propose = "3s"/timeout_propose = "1s"/g' $HOME_DIR/config/config.toml
	sed -i '' 's/index_all_keys = false/index_all_keys = true/g' $HOME_DIR/config/config.toml
	sed -i '' 's/pruning = "default"/pruning = "nothing"/g'	$HOME_DIR/config/app.toml
	sed -i '' '138s/enable = true/enable = false/g'       $HOME_DIR/config/app.toml
	sed -i '' '175s/enable = true/enable = false/g'       $HOME_DIR/config/app.toml
	sed -i '' 's/8080/8888/g'	$HOME_DIR/config/app.toml
	sed -i '' 's#"0.0.0.0:9090"#"0.0.0.0:'"$GRPCPORT"'"#g' $HOME_DIR/config/app.toml
	if ! [ -z "$APIPORT" ]; then
		sed -i '' '108s/enable = false/enable = true/g'	$HOME_DIR/config/app.toml
		sed -i '' 's#"tcp://0.0.0.0:1317"#"tcp://localhost:'"$APIPORT"'"#g' $HOME_DIR/config/app.toml
	fi
fi

sed -i -e 's/"voting_period": "172800s"/"voting_period": "20s"/' ./$HOME_DIR/config/genesis.json

# Start the kichain
#echo "starting the node"
#$BINARY --home $HOME_DIR start &> ./$HOME_DIR/node.log &
