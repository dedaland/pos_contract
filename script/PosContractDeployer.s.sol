// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {MerchantFundSplitter} from "../src/contract_v3.sol";

contract CounterScript is Script {
    address ACC0 = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
    address ACC1 = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;


    function setUp() public {}

    function run() external returns(MerchantFundSplitter) {
        vm.startBroadcast();
        MerchantFundSplitter fundsplitter = new MerchantFundSplitter(
            ACC0, // merchant address
            ACC1, // platform address
            250, // platform fee
            msg.sender
            );
        vm.stopBroadcast();
        return fundsplitter;
    }
}
