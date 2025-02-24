// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

import {IProxyAdmin} from "@eth-optimism-bedrock/interfaces/universal/IProxyAdmin.sol";
import {Constants} from "@eth-optimism-bedrock/src/libraries/Constants.sol";
import {IProxy} from "@eth-optimism-bedrock/interfaces/universal/IProxy.sol";

import {MockTarget} from "test/tasks/mock/MockTarget.sol";
import {MultisigTask} from "src/improvements/tasks/MultisigTask.sol";
import {AddressRegistry as Addresses} from "src/improvements/AddressRegistry.sol";

/// Mock task that upgrades the L1ERC721BridgeProxy implementation
/// to an example implementation address
contract MockMultisigTask is MultisigTask {
    address public constant newImplementation = address(1000);

    /// @notice reference to the mock target contract
    MockTarget public mockTarget;

    /// @notice Returns the safe address string identifier
    /// @return The string "SystemConfigOwner"
    function safeAddressString() public pure override returns (string memory) {
        return "ProxyAdminOwner";
    }

    /// @notice Returns the storage write permissions required for this task
    /// @return Array of storage write permissions
    function _taskStorageWrites() internal pure override returns (string[] memory) {
        string[] memory storageWrites = new string[](1);
        storageWrites[0] = "L1ERC721BridgeProxy";
        return storageWrites;
    }

    // no-op
    function _templateSetup(string memory) internal override {}

    function _build(uint256 chainId) internal override {
        IProxyAdmin proxy = IProxyAdmin(payable(addresses.getAddress("ProxyAdmin", chainId)));

        proxy.upgrade(
            payable(addresses.getAddress("L1ERC721BridgeProxy", getChain("optimism").chainId)), newImplementation
        );

        if (address(mockTarget) != address(0)) {
            /// set the snapshot ID for the MockTarget contract if the address is set
            mockTarget.setSnapshotIdTask(18291864375436131);
        }
    }

    function _validate(uint256 chainId) internal view override {
        IProxy proxy = IProxy(payable(addresses.getAddress("L1ERC721BridgeProxy", chainId)));
        bytes32 data = vm.load(address(proxy), Constants.PROXY_IMPLEMENTATION_ADDRESS);

        assertEq(bytes32(uint256(uint160(newImplementation))), data, "Proxy implementation not set correctly");
    }

    function addAction(address target, bytes memory data, uint256 value, string memory description) public {
        actions.push(Action(target, value, data, description));
    }
}
