//SPDX-License-Identifier:MIT

pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {IRouterClient} from "../lib/chainlink/contracts/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Client} from "../lib/chainlink/contracts/src/v0.8/ccip/libraries/Client.sol";
import {IERC20} from
    "../lib/chainlink/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol";

contract BridgeTokenScript is Script {
    function run(
        address receiverAddress,
        uint64 destinationChainSelector,
        address routerAddress,
        address tokenToSendAddress,
        uint256 amountToSend,
        address linkTokenAddress
    ) public {
        Client.EVMTokenAmount[] memory tokenAmounts = new Client.EVMTokenAmount[](1);
        tokenAmounts[0] = Client.EVMTokenAmount({token: tokenToSendAddress, amount: amountToSend});
        vm.startBroadcast();
        // Create an EVM2AnyMessage struct in memory with necessary information for sending a cross-chain message
        //  address(linkToken) means fees are paid in LINK
        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(receiverAddress),
            data: "",
            tokenAmounts: tokenAmounts,
            feeToken: linkTokenAddress,
            extraArgs: Client._argsToBytes(Client.EVMExtraArgsV1({gasLimit: 0}))
        });
        // Get the fee required to send the message
        uint256 ccipFee = IRouterClient(routerAddress).getFee(destinationChainSelector, message);

        // approve the Router to transfer LINK tokens on contract's behalf. It will spend the fees in LINK\
        IERC20(linkTokenAddress).approve(routerAddress, ccipFee);

        // approve the Router to spend tokens on contract's behalf. It will spend the amount of the given token
        IERC20(tokenToSendAddress).approve(routerAddress, amountToSend);

        IRouterClient(routerAddress).ccipSend(destinationChainSelector, message);
        vm.stopBroadcast();
    }
}
