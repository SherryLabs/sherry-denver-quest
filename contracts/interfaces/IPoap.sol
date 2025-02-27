// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

interface IPOAP {
    function ownerOf(uint256 tokenId) external view returns (address);
    function tokenEvent(uint256 tokenId) external view returns (uint256);
}
