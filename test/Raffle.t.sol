// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "../contracts/Raffle.sol"; // Assume your Raffle contract is in the src folder

contract RaffleTest is Test {
    Raffle raffle;
    uint16 totalUsers;

    // Test with 6 users
    function setUpForSix() public {
        totalUsers = 6;
        raffle = new Raffle(totalUsers); // Deploy the contract with 6 users
    }

    // Test with 10 users
    function setUpForTen() public {
        totalUsers = 10;
        raffle = new Raffle(totalUsers); // Deploy the contract with 10 users
    }

    // Test with 300 users
    function setUpForThreeHundred() public {
        totalUsers = 300;
        raffle = new Raffle(totalUsers); // Deploy the contract with 300 users
    }

    // Verify that the raffle can be executed correctly (6 users)
    function testPickWinnersSix() public {
        setUpForSix();
        raffle.pickWinners();

        uint16[5] memory winners = raffle.getWinners();

        // Verify that all winners are distinct
        for (uint i = 0; i < 5; i++) {
            for (uint j = i + 1; j < 5; j++) {
                assertNotEq(winners[i], winners[j], "Winner indexes should not be the same");
            }
        }

        // Verify that the raffle has been completed
        assertEq(raffle.raffleCompleted(), true, "Raffle should be completed after picking winners");
    }

    // Verify that the raffle can be executed correctly (10 users)
    function testPickWinnersTen() public {
        setUpForTen();
        raffle.pickWinners();

        uint16[5] memory winners = raffle.getWinners();

        // Verify that all winners are distinct
        for (uint i = 0; i < 5; i++) {
            for (uint j = i + 1; j < 5; j++) {
                assertNotEq(winners[i], winners[j], "Winner indexes should not be the same");
            }
        }

        // Verify that the raffle has been completed
        assertEq(raffle.raffleCompleted(), true, "Raffle should be completed after picking winners");
    }

    // Verify that the raffle can be executed correctly (300 users)
    function testPickWinnersThreeHundred() public {
        setUpForThreeHundred();
        raffle.pickWinners();

        uint16[5] memory winners = raffle.getWinners();

        // Verify that all winners are distinct
        for (uint i = 0; i < 5; i++) {
            for (uint j = i + 1; j < 5; j++) {
                assertNotEq(winners[i], winners[j], "Winner indexes should not be the same");
            }
        }

        // Verify that the raffle has been completed
        assertEq(raffle.raffleCompleted(), true, "Raffle should be completed after picking winners");
    }

    // Verify that the raffle cannot be executed more than once (6 users)
    function testRaffleAlreadyCompleted() public {
        setUpForSix();
        raffle.pickWinners();

        vm.expectRevert("Raffle already completed");
        raffle.pickWinners(); // This should revert, as the raffle has already been completed
    }
}
