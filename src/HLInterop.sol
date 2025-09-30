// SPDX-License-Identifier: UNLICENSED
//
// ------------------------------
// --   Hyperliquid interop    --
// --   through CoreWriter     --
// ------------------------------
pragma solidity ^0.8.30;

interface CoreWriter {
    function sendRawAction(bytes calldata data) external;
}

contract HLInterop {
    address constant CoreWriterAddr = 0x3333333333333333333333333333333333333333;
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");

        _;
    }

    constructor() {
        owner = msg.sender;
    }

    enum ActionKind {
        LimitOrder,
        VaultTransfer,
        TokenDelegate,
        StakingDeposit,
        StakingWithdraw,
        SpotSend,
        USDClassTransfer,
        FinalizeEVMContract,
        AddAPIWallet,
        CancelOrderByOID,
        CancelOrderByCLOID
    }

    function _executeAction(ActionKind actionKind, bytes memory encodedAction) internal {
        bytes memory data = new bytes(4 + encodedAction.length);
        data[0] = 0x01;
        data[1] = 0x00;
        data[2] = 0x00;

        // https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/hyperevm/interacting-with-hypercore
        // required +1 since enums are 0-indexed but action IDs start from 1
        data[3] = bytes1(uint8(actionKind) + 1);

        for (uint256 i = 0; i < encodedAction.length; i++) {
            data[4 + i] = encodedAction[i];
        }

        CoreWriter(CoreWriterAddr).sendRawAction(data);
    }

    function limitOrder(
        uint32 asset,
        bool isBuy,
        uint64 limitPx,
        uint64 sz,
        bool reduceOnly,
        uint8 encodedTif,
        uint128 cloid
    ) public onlyOwner {
        bytes memory encodedAction = abi.encode(asset, isBuy, limitPx, sz, reduceOnly, encodedTif, cloid);

        _executeAction(ActionKind.LimitOrder, encodedAction);
    }

    function VaultTransfer(uint64 ntl, bool toPerp) public onlyOwner {
        bytes memory encodedAction = abi.encode(ntl, toPerp);
        _executeAction(ActionKind.VaultTransfer, encodedAction);
    }

    function TokenDelegate(address validator, uint64 weiAmount, bool isUndelegate) public onlyOwner {
        bytes memory encodedAction = abi.encode(validator, weiAmount, isUndelegate);
        _executeAction(ActionKind.TokenDelegate, encodedAction);
    }

    function StakingDeposit(uint64 weiAmount) public onlyOwner {
        bytes memory encodedAction = abi.encode(weiAmount);
        _executeAction(ActionKind.StakingDeposit, encodedAction);
    }

    function StakingWithdraw(uint64 weiAmount) public onlyOwner {
        bytes memory encodedAction = abi.encode(weiAmount);
        _executeAction(ActionKind.StakingWithdraw, encodedAction);
    }

    function SpotSend(address destination, uint64 token, uint64 weiAmount) public onlyOwner {
        bytes memory encodedAction = abi.encode(destination, token, weiAmount);
        _executeAction(ActionKind.SpotSend, encodedAction);
    }

    function USDClassTransfer(uint64 ntl, bool toPerp) public onlyOwner {
        bytes memory encodedAction = abi.encode(ntl, toPerp);
        _executeAction(ActionKind.USDClassTransfer, encodedAction);
    }

    function FinalizeEVMContract(uint64 token, uint8 encodedFinalizeEvmContractVariant, uint64 createNonce)
        public
        onlyOwner
    {
        bytes memory encodedAction = abi.encode(token, encodedFinalizeEvmContractVariant, createNonce);
        _executeAction(ActionKind.FinalizeEVMContract, encodedAction);
    }

    function AddAPIWallet(address wallet, string memory name) public onlyOwner {
        bytes memory encodedAction = abi.encode(wallet, name);
        _executeAction(ActionKind.AddAPIWallet, encodedAction);
    }

    function CancelOrderByOID(uint32 asset, uint64 oid) public onlyOwner {
        bytes memory encodedAction = abi.encode(asset, oid);
        _executeAction(ActionKind.CancelOrderByOID, encodedAction);
    }

    function CancelOrderByCLOID(uint32 asset, uint128 cloid) public onlyOwner {
        bytes memory encodedAction = abi.encode(asset, cloid);
        _executeAction(ActionKind.CancelOrderByCLOID, encodedAction);
    }
}
