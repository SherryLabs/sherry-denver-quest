// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract Raffle {
    uint16 public totalUsers;
    uint16[5] public winners;
    bool public raffleCompleted;

    constructor(uint16 _totalUsers) {
        require(_totalUsers >= 6 && _totalUsers <= 300, "Users out of range");
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
        require(totalUsers >= 5, "Not enough registered users");

        uint16 available = totalUsers;
        uint16[] memory swapArray = new uint16[](available);

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
        }

        raffleCompleted = true; // Mark raffle as completed
    }

    /**
     * @dev Returns the selected winners.
     */
    function getWinners() public view returns (uint16[5] memory) {
        require(raffleCompleted, "Raffle not completed yet");
        return winners;
    }
}
