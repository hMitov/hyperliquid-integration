# Hyperliquid Integration

A Foundry-based integration for interacting with Hyperliquid's decentralized exchange through smart contracts. This project provides both a Solidity contract (`HLInterop.sol`) and a shell script (`hl.sh`) for seamless interaction with Hyperliquid's trading and vault operations.

## Overview

This integration allows you to:
- Deploy a smart contract that interfaces with Hyperliquid's CoreWriter
- Place limit orders on Hyperliquid
- Transfer USDC between spot and perp accounts
- Execute various Hyperliquid actions through smart contracts
- Use both contract-based and direct CoreWriter interactions

## Architecture

### HLInterop.sol
A Solidity contract that acts as an intermediary between your application and Hyperliquid's CoreWriter contract. It provides:

- **Action Encoding**: Properly encodes actions according to Hyperliquid's protocol
- **Access Control**: Owner-only functions for security
- **Multiple Action Types**: Support for various Hyperliquid operations

### hl.sh
A bash script that demonstrates:
- Contract deployment
- Direct trading operations
- Environment variable management
- Both contract-based and direct CoreWriter interactions

## Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- Bash shell
- Access to Hyperliquid testnet/mainnet

## Setup

1. **Clone and install dependencies**:
```bash
git clone https://github.com/hMitov/hyperliquid-integration.git
cd hyperliquid-integration
forge install
```

2. **Create environment file**:
```bash
cp .env.example .env
```

3. **Configure your environment** (`.env`):
```bash
HL_HTTP=https://rpc.hyperliquid-testnet.xyz/evm
PRIVKEY=your_private_key_here
HL_COREWRITER=0x3333333333333333333333333333333333333333
```

## Usage

### Quick Start

Run the complete example:
```bash
chmod +x hl.sh
./hl.sh
```

### Manual Operations

#### 1. Deploy Contract
```bash
# Load environment variables
source .env

forge create -r=$HL_HTTP \
    --private-key=$PRIVKEY \
    --broadcast \
    src/HLInterop.sol:HLInterop
```

#### 2. Place Limit Order (via Contract)
```bash
# Load environment variables
source .env

# Set contract address (from deployment step)
cnt=$CONTRACT_ADDR  # or use the actual deployed address

# Set trading parameters
ASSET_ID=135                      
IS_BUY=true                      
PRICE_X8=10700000000             
SIZE_X8=100000000                 
REDUCE_ONLY=false               
TIF=2                           
CLOID=0                         

cast s -r=$hl_http \
    --private-key=$PRIVKEY \
    --gas-limit 1000000 \
    $cnt \
    "limitOrder(uint32,bool,uint64,uint64,bool,uint8,uint128)" \
    $ASSET_ID $IS_BUY $PRICE_X8 $SIZE_X8 $REDUCE_ONLY $TIF $CLOID
```

#### 3. Transfer USDC (via Contract)
```bash
# Load environment variables
source .env

# Set contract address (from deployment step)
cnt=$CONTRACT_ADDR  # or use the actual deployed address

# Set transfer parameters
USD_TRANSFER_AMOUNT=500000        
USD_TRANSFER_TO_PERP=false       

cast s -r=$hl_http \
    --private-key=$PRIVKEY \
    --gas-limit 1000000 \
    $cnt \
    "USDClassTransfer(uint64,bool)" \
    $USD_TRANSFER_AMOUNT $USD_TRANSFER_TO_PERP
```

#### 4. Direct CoreWriter Interaction
```bash
# Load environment variables
source .env

# Set trading parameters
ASSET_ID=135                      
IS_BUY=true                      
PRICE_X8=10700000000             
SIZE_X8=100000000                 
REDUCE_ONLY=false               
TIF=2                           
CLOID=0   

# Encode action parameters
ENC=$(cast abi-encode "encode(uint32,bool,uint64,uint64,bool,uint8,uint128)" \
    $ASSET_ID $IS_BUY $PRICE_X8 $SIZE_X8 $REDUCE_ONLY $TIF $CLOID)

# Create payload
PAYLOAD="0x01000001${ENC#0x}"

# Send to CoreWriter
cast send --rpc-url $HL_HTTP \
    --private-key $PRIVKEY \
    --gas-limit 1000000 \
    $HL_COREWRITER \
    "sendRawAction(bytes)" $PAYLOAD
```

## Configuration

### Trading Parameters

The script uses these configurable parameters:

```bash
ASSET_ID=135                       # HYPE asset ID
IS_BUY=true                       # Buy order
PRICE_X8=10700000000              # $107 USDC * 1e8
SIZE_X8=100000000                 # 1 * 1e8
REDUCE_ONLY=false                 # Not a reduce-only order
TIF=2                             # Good-till-cancel
CLOID=0                           # Client order ID
USD_TRANSFER_AMOUNT=500000        # 0.5 USDC * 1e6
USD_TRANSFER_TO_PERP=false        # Transfer to spot
```

### Asset IDs

Find asset IDs using the Hyperliquid API:
```bash
curl -X POST \
    -H "Content-Type: application/json" \
    -d '{"type": "meta"}' \
    https://api.hyperliquid-testnet.xyz/info | jq '.universe | map(.name) | index("HYPE")'
```

## Available Actions

The `HLInterop` contract supports these Hyperliquid actions:

1. **LimitOrder** - Place limit orders
2. **VaultTransfer** - Transfer between vault accounts
3. **TokenDelegate** - Delegate tokens to validators
4. **StakingDeposit** - Deposit to staking
5. **StakingWithdraw** - Withdraw from staking
6. **SpotSend** - Send spot tokens
7. **USDClassTransfer** - Transfer USDC between spot/perp
8. **FinalizeEVMContract** - Finalize EVM contract
9. **AddAPIWallet** - Add API wallet
10. **CancelOrderByOID** - Cancel order by order ID
11. **CancelOrderByCLOID** - Cancel order by client order ID

## Action Encoding

Hyperliquid uses a specific action encoding format:

```solidity
bytes memory data = new bytes(4 + encodedAction.length);
data[0] = 0x01;                    // Version
data[1] = 0x00;                    // Reserved
data[2] = 0x00;                    // Reserved
data[3] = bytes1(uint8(actionKind) + 1);  // Action type (+1 for 1-indexed)
// ... encoded action data
```

## Security Considerations

⚠️ **Important Security Notes**:

1. **Private Key Management**: Never commit private keys to version control
2. **Environment Variables**: Use `.env` files for sensitive data
3. **Access Control**: The contract has owner-only functions
4. **Minimum Balance**: Ensure at least $10 USDC in contract for trading
5. **Testnet First**: Always test on testnet before mainnet

## API Reference

### CoreWriter Interface
```solidity
interface CoreWriter {
    function sendRawAction(bytes calldata data) external;
}
```

### Action Types
```solidity
enum ActionKind {
    LimitOrder, VaultTransfer, TokenDelegate,
    StakingDeposit, StakingWithdraw, SpotSend,
    USDClassTransfer, FinalizeEVMContract,
    AddAPIWallet, CancelOrderByOID, CancelOrderByCLOID
}
```

## Troubleshooting

### Common Issues

1. **"Failed to deserialize JSON"**: Check if user address exists on the network
2. **"Invalid string length"**: Verify contract address format
3. **"Could not parse function signature"**: Check ABI encoding syntax
4. **"Not owner"**: Ensure you're calling from the contract owner address

### Debug Commands

```bash
# Check contract deployment
cast code $CONTRACT_ADDRESS --rpc-url $HL_HTTP

# Verify environment variables
echo "HTTP: $HL_HTTP"
echo "CoreWriter: $HL_COREWRITER"

# Test API connectivity
curl -X POST -H "Content-Type: application/json" \
    -d '{"type":"meta"}' \
    https://api.hyperliquid-testnet.xyz/info
```

## Development

### Build
```bash
forge build
```

### Test
```bash
forge test
```

### Format
```bash
forge fmt
```

### Deploy Script
```bash
forge script script/Deploy.s.sol:DeployScript --rpc-url $HL_HTTP --private-key $PRIVKEY --broadcast
```

## License

UNLICENSED

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## Support

For issues and questions:
- Check the [Hyperliquid Documentation](https://hyperliquid.gitbook.io/hyperliquid-docs/)
- Review the [Foundry Book](https://book.getfoundry.sh/)
- Open an issue in this repository