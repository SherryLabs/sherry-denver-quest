// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Test.sol";
import "../contracts/POAPVerifier.sol";
import "../contracts/mock/IPOAPMock.sol";

contract POAPVerifierTest is Test {
    IPOAPMock poapMock;
    POAPVerifier poapVerifier;

    address user1 = address(0x1);
    address user2 = address(0x2);
    uint256 testPoapId = 42;

    event UserVerified(address indexed user);
    error OwnableUnauthorizedAccount(address account);

    function setUp() public {
        poapMock = new IPOAPMock();
        poapVerifier = new POAPVerifier(testPoapId, address(poapMock));
    }

    function testInitialState() public view {
        // Verify global variable is set correctly
        uint256 poapId = poapVerifier.poapId();
        address poapContractAddress = poapVerifier.poapContract();
        assertFalse(
            poapContractAddress != address(poapMock),
            "POAPContract not matching"
        );

        assertFalse(poapId != testPoapId, "POAPId not matching");
    }

    function testUserCanRegisterWithPoap() public {
        poapMock.setBalance(user1, testPoapId, 1);
        poapVerifier.checkAndRegister(user1);
        assertTrue(poapVerifier.verifiedUsers(user1));
    }

    function testUserCannotRegisterWithoutPoap() public {
        vm.expectRevert("User does not have the required POAP");
        poapVerifier.checkAndRegister(user2);
    }

    function testUserCannotRegisterTwice() public {
        poapMock.setBalance(user1, testPoapId, 1);
        poapVerifier.checkAndRegister(user1);
        vm.expectRevert("User already verified");
        poapVerifier.checkAndRegister(user1);
    }

    function testUserVerifiedEventEmitted() public {
        poapMock.setBalance(user1, testPoapId, 1);
        vm.expectEmit(true, true, false, false);
        emit UserVerified(user1);
        poapVerifier.checkAndRegister(user1);
    }

    function testGetVerifiedUsers() public {
        poapMock.setBalance(user1, testPoapId, 1);
        poapMock.setBalance(user2, testPoapId, 1);
        poapVerifier.checkAndRegister(user1);
        poapVerifier.checkAndRegister(user2);
        address[] memory users = poapVerifier.getVerifiedUsers();
        assertEq(users.length, 2);
        assertEq(users[0], user1);
        assertEq(users[1], user2);
    }

    function testOnlyOwnerCanFinishRegistration() public {
        vm.prank(user1);
        vm.expectRevert(
            abi.encodeWithSelector(OwnableUnauthorizedAccount.selector, user1)
        );
        poapVerifier.finishRegistration();
    }

    function testIsRegistrationFinished() public {
        poapMock.setBalance(user1, testPoapId, 1);
        poapMock.setBalance(user2, testPoapId, 1);
        poapVerifier.checkAndRegister(user1);
        poapVerifier.finishRegistration();
        vm.expectRevert("Registration has already ended");
        poapVerifier.checkAndRegister(user2);
        address[] memory users = poapVerifier.getVerifiedUsers();
        assertEq(users.length, 1);
    }
}
