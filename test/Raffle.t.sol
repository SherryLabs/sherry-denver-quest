// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "../contracts/Raffle.sol";
import "../contracts/POAPVerifier.sol";
import "../contracts/mock/IPOAPMock.sol";

contract RaffleTest is Test {
    Raffle raffle;
    IPOAPMock poapMock;
    POAPVerifier poapVerifier;
    IPOAPMock smallPoapMock;
    POAPVerifier smallPoapVerifier;
    address user1 = address(0x1);
    address user2 = address(0x2);
    address user3 = address(0x3);
    address user4 = address(0x4);
    address user5 = address(0x5);
    address user6 = address(0x6);
    address[] users;
    address owner = address(0x666);

    function setUp() public {
        // Create POAPVerifier contract
        poapMock = new IPOAPMock();
        poapVerifier = new POAPVerifier(1, address(poapMock));

        // Register users in POAPVerifier
        users.push(user1);
        users.push(user2);
        users.push(user3);
        users.push(user4);
        users.push(user5);
        users.push(user6);

        for (uint i = 0; i < users.length; i++) {
            poapMock.setBalance(users[i], 1, 1);
            poapVerifier.checkAndRegister(users[i]);
        }

        poapVerifier.finishRegistration();

        // Create Raffle contract
        raffle = new Raffle(address(poapVerifier));
    }

    function setupTestConstructor() internal {
        // Create POAPVerifier with less than 6 users to test constructor required
        smallPoapMock = new IPOAPMock();
        smallPoapVerifier = new POAPVerifier(2, address(smallPoapMock));
        smallPoapMock.setBalance(user1, 2, 1);
        smallPoapVerifier.checkAndRegister(user1);
        smallPoapMock.setBalance(user2, 2, 1);
        smallPoapVerifier.checkAndRegister(user2);
    }

    function testRegistrationNotFinished() public {
        // test constructor require
        setupTestConstructor();

        vm.expectRevert("Registration is not finished");
        new Raffle(address(smallPoapVerifier));
    }

    function testNotEnoughUsers() public {
        // test constructor require
        setupTestConstructor();

        smallPoapVerifier.finishRegistration();

        vm.expectRevert("Users out of range");
        new Raffle(address(smallPoapVerifier));
    }

    function testInitialState() public view {
        // Verify global variable is set correctly
        assertEq(raffle.totalUsers(), 6, "Total users should be 6");

        uint16[5] memory winners = raffle.getWinnersIndexes();
        assertEq(winners[0], 0, "Winners indexes should be not assigned yet");

        address[5] memory winnersAddresses = raffle.getWinners();
        assertEq(
            winnersAddresses[0],
            address(0),
            "Winners addresses should be not assigned yet"
        );

        POAPVerifier poapver = raffle.poapVerifier();
        assertFalse(
            address(poapver) != address(poapVerifier),
            "POAPVerifier not matching"
        );

        assertFalse(
            raffle.raffleCompleted(),
            "Raffle should not be completed initially"
        );
    }

    function testCannotPickWinnersTwice() public {
        raffle.pickWinners();

        // Try to pick winners again and expect an error
        vm.expectRevert("Raffle already completed");
        raffle.pickWinners();
    }

    function testPickWinners() public {
        raffle.pickWinners();

        // Check that the raffle has been completed
        assertTrue(raffle.raffleCompleted(), "Raffle should be completed");

        address[] memory verifiedUserList = poapVerifier.getVerifiedUsers();
        address[5] memory winners = raffle.getWinners();

        for (uint i = 0; i < 5; i++) {
            // Ensure that the winners indexes exists in poapverifier contract and match
            assertTrue(isValidWinner(winners[i]), "Invalid winner address");

            // Ensure that the winners are unique
            for (uint j = i + 1; j < 5; j++) {
                assertNotEq(winners[i], winners[j], "Winners should be unique");
            }

            // Ensure that the winners addresses match in poapverifier contract verified user list
            assertTrue(
                isValidVerifiedUser(winners[i], verifiedUserList),
                "User address is not a winner"
            );
        }
    }

    // Helper function to validate winner address
    function isValidWinner(address winner) internal view returns (bool) {
        for (uint i = 0; i < users.length; i++) {
            if (users[i] == winner) {
                return true;
            }
        }
        return false;
    }

    // Helper function to validate winner address
    function isValidVerifiedUser(
        address winner,
        address[] memory verifiedUserList
    ) internal pure returns (bool) {
        for (uint i = 0; i < verifiedUserList.length; i++) {
            if (verifiedUserList[i] == winner) {
                return true;
            }
        }
        return false;
    }
}
