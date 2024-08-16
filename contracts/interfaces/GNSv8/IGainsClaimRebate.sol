// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IGainsClaimRebate {
    function claimMultipleRewards(
        uint256[] calldata _epochs,
        uint256[] calldata _rewardAmounts,
        bytes32[][] calldata _proofs
    ) external;
}
