
## Repository structure

```markdown
.
├── bin // binary for different chains
│   ├── gaiad-v7.0.2-linux-amd64
│   ├── hermes
│   ├── junod-v6
│   ├── junod-v7
│   ├── kid-Testnet-3.0.0-beta
│   ├── kid-Testnet-4.0.0-alpha
│   ├── wasm-v27
│   └── wasm-v28
├── hermes  // configurations and script for the relayer
│   ├── README.md
│   ├── config.toml   // hermes configuration file
│   ├── create-conn.sh  //create a connection between 2 chains
│   ├── restore-keys.sh   // restore the relayer wallets from mnemonic
│   ├── start.sh  // start the relayer
│   └── variables.sh
├── run-upgrade.sh  // allows to create and vote an upgrade gov proposal
├── fast-deploy.sh  // allows to deploy a chain with the given ports and client
└── txs   // sample ica transactions
    ├── tx_send_wasm_ki.json
    ├── tx_send_wasm_wasm.json
```

You might need to download the various client release yourself. Here are the links to the official repositories

- [gaiad-v7.0.2-linux-amd64](https://github.com/cosmos/gaia/releases/tag/v7.0.2)
- [junod-v6](https://github.com/CosmosContracts/juno/releases/tag/v6.0.0)
- [junod-v7](https://github.com/CosmosContracts/juno/releases/tag/v7.0.0)
- [kid-Testnet-3.0.0-beta](https://github.com/KiFoundation/ki-tools/releases/tag/3.0.0-beta)
- [kid-Testnet-4.0.0-alpha](https://github.com/KiFoundation/ki-tools/releases/tag/4.0.0-alpha.0) (run `make build-testnet`)
- [wasm-v27](https://github.com/CosmWasm/wasmd/tree/v0.27.0)
- [wasm-v28](https://github.com/CosmWasm/wasmd/tree/v0.28.0)


The tests in this repo use `hermes v0.15.0`
- [hermes](https://github.com/informalsystems/ibc-rs/releases/tag/v0.15.0)

## Test 1 :  Wasmd <> Wasmd
Deploy the first chain
```bash
./fast-deploy.sh ./bin/wasm-v28 wasm-v28-ica tests/1001 46657 46656 9494 9094 uwasm 4317
./bin/wasm-v28 start --home tests/1001/wasm-v28-ica 2> tests/1001/wasm-v28-ica/node.log &
```

Deploy the second chain
```bash
./fast-deploy.sh ./bin/wasm-v28 wasm-v28-ica-2 tests/1001 36657 36656 9393 9093 uwasm 3317
./bin/wasm-v28 start --home tests/1001/wasm-v28-ica-2 2> tests/1001/wasm-v28-ica-2/node.log &
```

Add the relaye keys
```bash
cd hermes/
./restore-keys.sh wasm-v28-ica wasm-v28-ica-2
```

Create the connection between the 2 newly created chains
```bash
./create-conn.sh wasm-v28-ica wasm-v28-ica-2
```

Start the relayer
```bash
./start.sh
```

Store the wallet addresses to be used in the tests into variable
```bash
export WALLET_1=$(./bin/wasm-v28 keys show wallet-1 -a --keyring-backend test --home ./tests/1001/wasm-v28-ica) && echo $WALLET_1;
export WALLET_2=$(./bin/wasm-v28 keys show wallet-2 -a --keyring-backend test --home ./tests/1001/wasm-v28-ica) && echo $WALLET_2;
export WALLET_3=$(./bin/wasm-v28 keys show wallet-3 -a --keyring-backend test --home ./tests/1001/wasm-v28-ica-2) && echo $WALLET_3;
```

Register an interchain account (controller is `WALLLET_1` on chain `wasm-v28-ica` and host is chain `wasm-v28-ica`)
```bash
./bin/wasm-v28 tx intertx register --from $WALLET_1 --connection-id connection-0 --chain-id wasm-v28-ica --home ./tests/1001/wasm-v28-ica --node tcp://localhost:46657 --keyring-backend test -y
```

Store the address of the ICA account into a variable
```bash
export ICA_ADDR=$(./bin/wasm-v28 query intertx interchainaccounts connection-0 $WALLET_1 --home ./tests/1001/wasm-v28-ica --node tcp://localhost:46657  -o json | jq -r '.interchain_account_address') && echo $ICA_ADDR
```

Query the interchain account balance on the host chain. It should be empty.
```bash
./bin/wasm-v28 q bank balances $ICA_ADDR --chain-id wasm-v28-ica-2 --home ./tests/1001/wasm-v28-ica-2  --node tcp://localhost:36657
```

Send funds to the interchain account.
```bash
./bin/wasm-v28 tx bank send $WALLET_3 $ICA_ADDR 100000000uwasm --chain-id wasm-v28-ica-2 --home ./tests/1001/wasm-v28-ica-2 --node tcp://localhost:36657 --keyring-backend test -y
```

Query the balance once again and observe the changes
```bash
./bin/wasm-v28 q bank balances $ICA_ADDR --chain-id wasm-v28-ica-2 --home ./tests/1001/wasm-v28-ica-2 --node tcp://localhost:36657
```

Submit a bank send tx using the interchain account via ibc
```bash
./bin/wasm-v28 tx intertx submit txs/tx_send_wasm_wasm.json --connection-id connection-0 --from $WALLET_1 --chain-id wasm-v28-ica --home ./tests/1001/wasm-v28-ica --node tcp://localhost:46657  --keyring-backend test -y
```

## Test 2 :  Wasmd <> kid
We are using the wasm chain created in Test1 as controller chain

Deploy the kichain chain
```bash
./fast-deploy.sh bin/kid-Testnet-3.0.0-beta chain-2 tests/1001 56657 56656 9595 9095 utki 5317
./bin/kid-Testnet-3.0.0-beta start --home tests/1001/chain-2 2> tests/1001/chain-2/node.log &
```

Run the upgrade
```bash
./run-upgrade.sh ./bin/kid-Testnet-3.0.0-beta chain-2 ./tests/1001 56657 utki 5317 v4
```

Kill the chain when it halts and start with the ica enabled client
```bash
/bin/kid-Testnet-4.0.0-alpha start --home ./tests/1001/chain-2/ 2> tests/1001/chain-2/node.log &
```

Add the relaye keys
```bash
cd hermes/
./restore-keys.sh chain-2 wasm-v28-ica
```

Create the connection between the 2 newly created chains
```bash
./create-conn.sh wasm-v28-ica chain-2
```

Start the relayer
```bash
./start.sh
```

Register an interchain account (controller is `WALLLET_1` on chain `wasm-v28-ica` and host is chain `chain-2`)
```bash
./bin/wasm-v28 tx intertx register --from $WALLET_1 --connection-id connection-1 --chain-id wasm-v28-ica --home ./tests/1001/wasm-v28-ica --node tcp://localhost:46657 --keyring-backend test -y
```

Store the address of the ICA account into a variable
```bash
export ICA_ADDR=$(./bin/wasm-v28 query intertx interchainaccounts connection-1 $WALLET_1 --home ./tests/1001/wasm-v28-ica --node tcp://localhost:46657  -o json | jq -r '.interchain_account_address') && echo $ICA_ADDR
```

Query the interchain account balance on the host chain. It should be empty.
```bash
./bin/kid-Testnet-4.0.0-alpha q bank balances $ICA_ADDR --chain-id chain-2 --node tcp://localhost:56657
```

Send funds to the interchain account.
```bash
export WALLET_4=$(./bin/kid-Testnet-4.0.0-alpha keys show wallet-4 -a --keyring-backend test --home ./tests/1001/chain-2) && echo $WALLET_4;
```

```bash
./bin/kid-Testnet-4.0.0-alpha tx bank send $WALLET_4 $ICA_ADDR 100000000utki --chain-id chain-2 --home ./tests/1001/chain-2 --node tcp://localhost:56657 --keyring-backend test -y
```

Query the balance once again and observe the changes
```bash
./bin/kid-Testnet-4.0.0-alpha q bank balances $ICA_ADDR --chain-id chain-2 --home ./tests/1001/chain-2 --node tcp://localhost:56657
```

Submit a bank send tx using the interchain account via ibc
```bash
./bin/wasm-v28 tx intertx submit txs/tx_send_wasm_ki.json --connection-id connection-1 --from $WALLET_1 --chain-id wasm-v28-ica --home ./tests/1001/wasm-v28-ica --node tcp://localhost:46657  --keyring-backend test -y
```
