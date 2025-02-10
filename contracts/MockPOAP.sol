// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MockPOAP is ERC1155, Ownable {
    constructor() ERC1155("https://sherry.social") Ownable(msg.sender) {}

    /**
     * @dev Mint a single POAP for a specific address.
     * @param to The recipient address.
     * @param tokenId The ID of the POAP.
     */
    function mint(address to, uint256 tokenId) external onlyOwner {
        _mint(to, tokenId, 1, "");
    }

    /**
     * @dev Mint multiple POAPs in a batch.
     * @param to The recipient address.
     * @param tokenIds Array of POAP IDs.
     * @param amounts Array of amounts corresponding to each POAP ID.
     * @param data Additional data (optional).
     */
    function mintBatch(
        address to,
        uint256[] memory tokenIds,
        uint256[] memory amounts,
        bytes memory data
    ) external onlyOwner {
        require(tokenIds.length == amounts.length, "Mismatched arrays length");
        _mintBatch(to, tokenIds, amounts, data);
    }

}
