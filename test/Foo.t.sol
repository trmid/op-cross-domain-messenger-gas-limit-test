// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "forge-std/console2.sol";

import { ICrossDomainMessenger } from "../src/interfaces/ICrossDomainMessenger.sol";
import { IMessageExecutor } from "../src/interfaces/IMessageExecutor.sol";
import { MessageDispatcherOptimism } from "../src/ethereum-optimism/EthereumToOptimismDispatcher.sol";

contract TestMessageDispatcherOptimism is Test {

  /* ============ Global Variables ============ */
  uint256 public mainnetFork;

  address public crossDomainMessenger = 0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1;

  MessageDispatcherOptimism public dispatcher;

  uint256 recentMainnetBlock = 17993284;
  uint256 blockBeforeBedrockUpgrade = 16473770; // use this for fork to see how it use to not affect the gas usage on L1

  /* ============ Set Up ============ */
  function setUp() public {
    mainnetFork = vm.createFork(vm.rpcUrl("mainnet"), 17993284);
  }

  /* ============ test ============ */
  function testForkGasLimit() external {
    useMainnet();

    uint256 MAX_GAS_LIMIT = 1_920_000;
    uint256 MIN_GAS_LIMIT = 0;
    bytes memory _calldata = bytes("some decently long calldata that is invalid, but should be just fine unless there are some actual pre-checks on calldata to make sure it executes.");

    // call dispatchMessage once before to reduce gas from any initialization of storage, .etc
    dispatcher.dispatchMessage(5, address(2), MAX_GAS_LIMIT, _calldata);

    uint8 iterations = 10;
    for (uint i = iterations; i > 0; i--) {
      uint256 _gasLimit = (MAX_GAS_LIMIT * i) / iterations;
      if (_gasLimit >= MIN_GAS_LIMIT) {
        vm.roll(block.number + 1); // make sure we aren't increasing fees artificially by submitting multiple calls per block
        uint256 gas0 = gasleft();
        dispatcher.dispatchMessage(5, address(2), _gasLimit, _calldata);
        uint256 gas1 = gasleft();
        console2.log("%s gasLimit, L1 gasConsumed: %s", _gasLimit, gas0 - gas1);
      }
    }
  }

  /* ============ Helpers ============ */

  /// @dev Run at the beginning of each fork test
  function useMainnet() public {
    vm.selectFork(mainnetFork);
    dispatcher = new MessageDispatcherOptimism(ICrossDomainMessenger(crossDomainMessenger), 5);
    dispatcher.setExecutor(IMessageExecutor(address(1)));
  }

}