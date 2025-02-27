// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IPoap.sol";

contract MockPOAP is IPOAP, Ownable {
    mapping(uint256 => address) tokenOwners;
    mapping(uint256 => uint256) tokenEvents;

    constructor() Ownable(msg.sender) {}

    function setTokenOwner(uint256 tokenId, address owner) external onlyOwner {
        require(tokenId != 0, "TokenId required");
        require(owner != address(0), "Owner required");
        tokenOwners[tokenId] = owner;
    }

    function setTokenEvent(uint256 tokenId, uint256 eventId) external onlyOwner {
        require(tokenId != 0, "TokenId required");
        require(eventId != 0, "EventId required");
        tokenEvents[tokenId] = eventId;
    }

    function ownerOf(uint256 tokenId) external view returns (address) {
        return tokenOwners[tokenId];
    }

    function tokenEvent(uint256 tokenId) external view returns (uint256) {
        return tokenEvents[tokenId];
    }
}
