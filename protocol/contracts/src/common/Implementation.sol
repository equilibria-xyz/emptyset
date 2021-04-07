/*
    Copyright 2021 Empty Set Squad <emptysetsquad@protonmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/Address.sol";
import "../Interfaces.sol";
import "./IImplementation.sol";

/**
 * @title Implementation
 * @notice Common functions and accessors across upgradeable, ownable contracts
 */
contract Implementation is IImplementation {

    /**
     * @dev Storage slot with the address of the current implementation
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1
     */
    bytes32 private constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Storage slot with the admin of the contract
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1
     */
    bytes32 internal constant ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    // UPGRADEABILITY

    /**
     * @notice Returns the current implementation
     * @return Address of the current implementation
     */
    function implementation() external view returns (address impl) {
        bytes32 slot = IMPLEMENTATION_SLOT;
        assembly {
            impl := sload(slot)
        }
    }

    /**
     * @notice Returns the current proxy admin contract
     * @return Address of the current proxy admin contract
     */
    function admin() external view returns (address adm) {
        bytes32 slot = ADMIN_SLOT;
        assembly {
            adm := sload(slot)
        }
    }

    // REGISTRY

    /**
     * @notice Updates the registry contract
     * @dev Owner only - governance hook
     *      If registry is already set, the new registry's timelock must match the current's
     * @param newRegistry New registry contract
     */
    function setRegistry(address newRegistry) external onlyOwner {
        IRegistry registry = registry();

        require(newRegistry != address(0), "Implementation: zero address");
        require(
            (address(registry) == address(0) && Address.isContract(newRegistry)) ||
                IRegistry(newRegistry).timelock() == registry.timelock(),
            "Implementation: timelocks must match"
        );

        _setRegistry(newRegistry);

        emit RegistryUpdate(newRegistry);
    }

    // OWNER

    /**
     * @notice Takes ownership over a contract if none has been set yet
     * @dev Needs to be called initialize ownership after deployment
     *      Ensure that this has been properly set before using the protocol
     */
    function takeOwnership() external {
        require(owner() == address(0), "Implementation: already initialized");

        _setOwner(msg.sender);

        emit OwnerUpdate(msg.sender);
    }

    /**
     * @notice Updates the owner contract
     * @dev Owner only - governance hook
     * @param newOwner New owner contract
     */
    function setOwner(address newOwner) external onlyOwner {
        require(newOwner != address(this), "Implementation: this");
        require(Address.isContract(newOwner), "Implementation: not contract");

        _setOwner(newOwner);

        emit OwnerUpdate(newOwner);
    }

    /**
     * @dev Only allow when the caller is the owner address
     */
    modifier onlyOwner {
        require(msg.sender == owner(), "Implementation: not owner");

        _;
    }
}
