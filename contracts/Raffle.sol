// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./POAPVerifier.sol"; // Import the POAPVerifier contract

contract Raffle {
    uint16 public totalUsers;
    uint16[5] public winners;
    bool public raffleCompleted;

    address[5] public winnerAddresses;

    POAPVerifier public poapVerifier;

    constructor(address _poapVerifierAddress) {
        poapVerifier = POAPVerifier(_poapVerifierAddress);
        require(
            poapVerifier.isRegistrationFinished(),
            "Registration is not finished"
        );
        uint16 _totalUsers = uint16(poapVerifier.getVerifiedUsers().length);
        require(_totalUsers > 5, "Users out of range");
        totalUsers = _totalUsers;
    }

    /**
     * @dev Generates a pseudo-random number using block variables and a seed.
     */
    function getRandomNumber(uint16 seed) private view returns (uint16) {
        return
            uint16(
                uint(
                    keccak256(
                        abi.encodePacked(
                            block.timestamp,
                            block.prevrandao,
                            msg.sender,
                            seed
                        )
                    )
                )
            );
    }

    /**
     * @dev Selects 5 random winners using the Fisher-Yates Shuffle algorithm.
     * Can only be executed once.
     */
    function pickWinners() public {
        require(!raffleCompleted, "Raffle already completed");

        uint16 available = totalUsers;
        uint16[] memory swapArray = new uint16[](available);
        address[] memory verifiedUsers = poapVerifier.getVerifiedUsers();

        for (uint16 i = 0; i < 5; i++) {
            uint16 randIndex = getRandomNumber(i) % available;

            // Select the winner
            winners[i] = (swapArray[randIndex] == 0)
                ? randIndex
                : swapArray[randIndex];

            // Move the last available number to the chosen position
            swapArray[randIndex] = (swapArray[available - 1] == 0)
                ? available - 1
                : swapArray[available - 1];

            available--; // Reduce available range

            // Map winners to their addresses from verifiedUserList
            winnerAddresses[i] = verifiedUsers[winners[i]];
        }

        raffleCompleted = true; // Mark raffle as completed
    }

    /**
     * @dev Returns the selected winners' addresses.
     */
    function getWinners() public view returns (address[5] memory) {
        require(raffleCompleted, "Raffle not completed yet");
        return winnerAddresses;
    }
}
