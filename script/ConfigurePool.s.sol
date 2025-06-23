//SPDX-License-Identifier:MIT

pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {RateLimiter} from "../lib/chainlink/contracts/src/v0.8/ccip/libraries/RateLimiter.sol";
import {TokenPool} from "../lib/chainlink/contracts/src/v0.8/ccip/pools/TokenPool.sol";

contract ConfigurePoolScript is Script {
    function run(
        address localPool,
        uint64 remoteChainSelector,
        address remotePool,
        address remoteToken,
        bool outBoundRateLimiterIsEnabled,
        uint128 outBoundRateLimiterCapacity,
        uint128 outBoundRateLimiterRate,
        bool inBoundRateLimiterIsEnabled,
        uint128 inBoundRateLimiterCapacity,
        uint128 inBoundRateLimiterRate
    ) public {
        vm.startBroadcast();
        bytes[] memory remotePoolAddresses = new bytes[](1);
        remotePoolAddresses[0] = abi.encode(remotePool);

        TokenPool.ChainUpdate[] memory chainsToAdd = new TokenPool.ChainUpdate[](1);
        chainsToAdd[0] = TokenPool.ChainUpdate({
            remoteChainSelector: remoteChainSelector, // Remote chain selector
            remotePoolAddresses: remotePoolAddresses, // Address of the remote pool, ABI encoded in the case of a remote EVM chain.
            remoteTokenAddress: abi.encode(remoteToken), // Address of the remote token, ABI encoded in the case of a remote EVM chain
            outboundRateLimiterConfig: RateLimiter.Config({
                isEnabled: outBoundRateLimiterIsEnabled,
                capacity: outBoundRateLimiterCapacity,
                rate: outBoundRateLimiterRate
            }), // Outbound rate limited config, meaning the rate limits for all of the onRamps for the given chain
            inboundRateLimiterConfig: RateLimiter.Config({
                isEnabled: inBoundRateLimiterIsEnabled,
                capacity: inBoundRateLimiterCapacity,
                rate: inBoundRateLimiterRate
            })
        });
        TokenPool(localPool).applyChainUpdates(new uint64[](0), chainsToAdd);
        vm.stopBroadcast();
    }
}
