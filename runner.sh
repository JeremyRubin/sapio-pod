#!/bin/sh
export ELECTRON_START_URL='http://localhost:3000'
export BROWSER=none
export REACT_EDITOR=none 
export SAPIO_BITCOIN_RPC_USER="ubitcoin"
export SAPIO_BITCOIN_RPC_PASSWORD=$(head -n 4096 /dev/urandom | shasum -a 256 | cut -d' ' -f 1)
export SAPIO_BITCOIN_RPC_PORT=18443
export SAPIO_BITCOIN_RPC_HOST=0.0.0.0
export SAPIO_BITCOIN_NETWORK="regtest"
export SAPIO_ORACLE_SEED_FILE='/home/app/ORACLE_SEED'
export SAPIO_ORACLE_NET=0.0.0.0:8010
export SAPIO_CLI_BINARY='/home/app/sapio-cli'

chown -R ubitcoin:ubitcoin /home/ubitcoin/.bitcoin
su ubitcoin -c "cd && ./rpcauth.py ubitcoin $SAPIO_BITCOIN_RPC_PASSWORD | head -n2 | tail -n 1 >> .bitcoin/bitcoin.conf"
su ubitcoin -c "cd && ./bin/bitcoind"
# Wait for Bitcoind to be started before proceeding
su ubitcoin -c "cd && \$(while ! ./bin/bitcoin-cli ping; do sleep 1; done)"
su ubitcoin -c "cd && ./bin/bitcoin-cli createwallet \"default\" && ./bin/bitcoin-cli loadwallet \"default\""
su ubitcoin -c "cd && ./bin/bitcoin-cli -generate 200"

su app -c "cd && head -n 4096 /dev/urandom | shasum -a 256 |cut -d' ' -f 1 > ORACLE_SEED"
su app -c "cd && cd sapio-studio && yarn serve build -l 3000 -n"&
su app -c "cd && cd sapio-studio && yarn electron ."

