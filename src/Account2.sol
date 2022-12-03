// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

import "solmate/auth/Owned.sol";
import "solmate/auth/Auth.sol";

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
}
contract Account2 is Owned {
    constructor() Owned(msg.sender) {}

    function executeAsRelay(
        address toCall,
        bytes calldata params,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {

        // validate signature
        bytes32 hash = keccak256(abi.encodePacked(toCall, params));
        address signer = ecrecover(hash, v, r, s);
        require(signer == owner && signer != address(0), "invalid signature");

        (bool success, bytes memory data) = toCall.call(params);
    }

    function executeWithEconomicAbstraction(
        address toCall,
        bytes calldata params,
        uint256 gasTokenRatio,  // preferably >x, x = gas price in token
        address gasToken
    ) internal {

        uint256 gasUsed = gasleft();
        (bool success, bytes memory data) = toCall.call(params);
        gasUsed -= gasleft() + 21000;

        uint256 amount = (gasUsed * gasTokenRatio);
        uint256 balance = IERC20(gasToken).balanceOf(address(this));
        amount = amount > balance ? balance : amount;
        require(IERC20(gasToken).transfer(tx.origin, amount), 'gasToken balance too low');
    }

    function executeAsOwner(
        address toCall,
        bytes calldata params
    ) external onlyOwner {
        
        (bool success, bytes memory data) = toCall.call(params);
    }
}