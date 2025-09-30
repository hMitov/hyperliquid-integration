#!/usr/bin/env bash
set -euo pipefail

# load env file if exists
if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
fi

hl_http="$HL_HTTP"
privkey="$PRIVKEY"
hl_corewriter="$HL_COREWRITER"

ASSET_ID=135                       # HYPE
IS_BUY=true
PRICE_X8=10700000000               # $107 USDC * 1e8
SIZE_X8=100000000                  # 1 * 1e8
REDUCE_ONLY=false
TIF=2                              # good-till-cancel
CLOID=0
USD_TRANSFER_AMOUNT=500000          # 0.5 USDC * 1e6 (or 1e? depending on HL scale)
USD_TRANSFER_TO_PERP=false

# deploy the contract
CONTRACT_ADDR=$(forge create -r=$hl_http \
    --private-key=$privkey \
    --broadcast \
    src/HLInterop.sol:HLInterop | grep "Deployed to:" | awk '{print $3}')

# export the deployed to contract addr
cnt=$CONTRACT_ADDR

# make sure to send at least $10 to the contract's address as that's the minimum requirement
# set by Hyperliquid to be able to open a position
# Do not do this in production as the contract is not well equipped to recover the sent funds

# opens a limit order 
cast s -r=$hl_http \
    --private-key=$privkey \
    --gas-limit=1000000 \
    $cnt \
    "limitOrder(uint32,bool,uint64,uint64,bool,uint8,uint128)" \
    $ASSET_ID $IS_BUY $PRICE_X8 $SIZE_X8 $REDUCE_ONLY $TIF $CLOID

# dissected parameters
# 1: 135 is the asset ID for Hype 
# can be checked by running 
curl -X POST \
    -H "Content-Type: application/json" \
    -d '{"type": "meta"}' \
    https://api.hyperliquid-testnet.xyz/info | jq '.universe | map(.name) | index("HYPE")'
# 2: isBuy == true
# 3: the price times 10^8, so pay $107USDC
# 4: amount of the asset times 10^8, in this case only 1
# 5: reduceOnly == false
# 6: tif == good-till-cancel - stays active until filled or manually cancelled
# 7: no cloid encoding

# swapping USDC from Perps to SPOT:
cast s -r=$hl_http \
    --private-key=$privkey \
    $cnt \
    --gas-limit=1000000 \
    "USDClassTransfer(uint64,bool)" \
    $USD_TRANSFER_AMOUNT $USD_TRANSFER_TO_PERP


ENC=$(cast abi-encode "encode(uint32,bool,uint64,uint64,bool,uint8,uint128)" \
    $ASSET_ID $IS_BUY $PRICE_X8 $SIZE_X8 $REDUCE_ONLY $TIF $CLOID)

PAYLOAD="0x01000001${ENC#0x}"

# Send directly to CoreWriter
cast send --rpc-url $hl_http \
	--private-key $privkey \
	--gas-limit 1000000 \
    $hl_corewriter \
  "sendRawAction(bytes)" $PAYLOAD | grep -v logs