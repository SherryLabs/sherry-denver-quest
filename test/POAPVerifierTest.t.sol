// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Test.sol";
import "../contracts/POAPVerifier.sol";
import "../contracts/mock/MockPOAP.sol";

contract POAPVerifierTest is Test {
    POAPVerifier public poapVerifier;
    MockPOAP public mockPOAP;

    address public owner = address(0x1);
    address public user1 = address(0x2);
    address public user2 = address(0x3);
    address public user3 = address(0x4);

    uint256 public eventId = 1;
    uint256 public tokenId1 = 100;
    uint256 public tokenId2 = 101;
    uint256 public tokenId3 = 102;

    function setUp() public {
        // Deploy MockPOAP contract
        mockPOAP = new MockPOAP();

        // Set token owners in MockPOAP
        mockPOAP.setTokenOwner(tokenId1, user1);
        mockPOAP.setTokenOwner(tokenId2, user2);
        mockPOAP.setTokenOwner(tokenId3, user3);

        // Set token events in MockPOAP
        mockPOAP.setTokenEvent(tokenId1, eventId);
        mockPOAP.setTokenEvent(tokenId2, eventId);
        mockPOAP.setTokenEvent(tokenId3, eventId);

        // Deploy POAPVerifier contract
        poapVerifier = new POAPVerifier(eventId, address(mockPOAP));

        mockPOAP.transferOwnership(owner);
        poapVerifier.transferOwnership(owner);
    }

    function testInitialization() public view {
        assertEq(poapVerifier.eventId(), eventId);
        assertEq(address(poapVerifier.poapContract()), address(mockPOAP));
        assertEq(poapVerifier.registrationFinished(), false);
    }

    function testRegisterUser() public {
        vm.prank(user1);
        poapVerifier.registerUser(user1);

        assertTrue(poapVerifier.registeredUsers(user1));
        assertEq(poapVerifier.getRegisteredUsers().length, 1);
        assertEq(poapVerifier.getRegisteredUsers()[0], user1);
    }

    function testRegisterUserAfterFinish() public {
        vm.prank(owner);
        poapVerifier.finishRegistration();

        vm.prank(user1);
        vm.expectRevert("Registration has already ended");
        poapVerifier.registerUser(user1);
    }

    function testFinishRegistration() public {
        vm.prank(owner);
        poapVerifier.finishRegistration();

        assertTrue(poapVerifier.registrationFinished());
    }

    function testCheckRegisteredUsers() public {
        // Register users
        vm.prank(user1);
        poapVerifier.registerUser(user1);

        vm.prank(user2);
        poapVerifier.registerUser(user2);

        // Finish registration
        vm.prank(owner);
        poapVerifier.finishRegistration();

        // Verify users
        uint32[] memory tokenIds = new uint32[](2);
        tokenIds[0] = uint32(tokenId1);
        tokenIds[1] = uint32(tokenId2);

        vm.prank(owner);
        poapVerifier.checkRegisteredUsers(tokenIds);

        // Verify that users are verified
        assertTrue(poapVerifier.verifiedUsers(user1));
        assertTrue(poapVerifier.verifiedUsers(user2));
        assertEq(poapVerifier.getVerifiedUsers().length, 2);
        assertEq(poapVerifier.getVerifiedUsers()[0], user1);
        assertEq(poapVerifier.getVerifiedUsers()[1], user2);
    }

    function testRegisterUserRejectsDuplicates() public {
        // Register a user for the first time
        vm.prank(user1);
        poapVerifier.registerUser(user1);

        // Verify that the user is registered
        assertTrue(
            poapVerifier.registeredUsers(user1),
            "User should be registered"
        );

        // Try to register the same user again
        vm.prank(user1);
        vm.expectRevert("User already registered");
        poapVerifier.registerUser(user1);

        // Verify that the registered users list contains only one entry
        address[] memory registeredUsers = poapVerifier.getRegisteredUsers();
        assertEq(
            registeredUsers.length,
            1,
            "There should be only one registered user"
        );
        assertEq(
            registeredUsers[0],
            user1,
            "The registered user should be user1"
        );
    }

    function testCheckRegisteredUsersWrongEvent() public {
        // Register users
        vm.prank(user1);
        poapVerifier.registerUser(user1);

        // Finish registration
        vm.prank(owner);
        poapVerifier.finishRegistration();

        // Set a token with an incorrect eventId
        vm.prank(owner);
        mockPOAP.setTokenEvent(tokenId1, eventId + 1);

        uint32[] memory tokenIds = new uint32[](1);
        tokenIds[0] = uint32(tokenId1);

        vm.prank(owner);
        vm.expectRevert("EventId don't belongs to the Raffle");
        poapVerifier.checkRegisteredUsers(tokenIds);
    }

    function testCheckRegisteredUsersBeforeFinish() public {
        // Register users
        vm.prank(user1);
        poapVerifier.registerUser(user1);

        uint32[] memory tokenIds = new uint32[](1);
        tokenIds[0] = uint32(tokenId1);

        vm.prank(owner);
        vm.expectRevert("Registration is not finished");
        poapVerifier.checkRegisteredUsers(tokenIds);
    }

    function testGetUserLists() public {
        // Register users
        vm.prank(user1);
        poapVerifier.registerUser(user1);

        vm.prank(user2);
        poapVerifier.registerUser(user2);

        // Finish registration
        vm.prank(owner);
        poapVerifier.finishRegistration();

        // Verify users
        uint32[] memory tokenIds = new uint32[](2);
        tokenIds[0] = uint32(tokenId1);
        tokenIds[1] = uint32(tokenId2);

        vm.prank(owner);
        poapVerifier.checkRegisteredUsers(tokenIds);

        // Get lists
        address[] memory registeredUsers = poapVerifier.getRegisteredUsers();
        address[] memory verifiedUsers = poapVerifier.getVerifiedUsers();

        assertEq(registeredUsers.length, 2);
        assertEq(verifiedUsers.length, 2);
        assertEq(registeredUsers[0], user1);
        assertEq(registeredUsers[1], user2);
        assertEq(verifiedUsers[0], user1);
        assertEq(verifiedUsers[1], user2);
    }

    function testCheckRegisteredUsersWithRepeatedTokenIds() public {
        // Create 15 unique users and assign tokenIds
        address[] memory users = new address[](15);
        uint32[] memory tokenIdsBatch1 = new uint32[](10); // First batch of 10 tokenIds
        uint32[] memory tokenIdsBatch2 = new uint32[](10); // Second batch of 10 tokenIds

        for (uint256 i = 0; i < 15; i++) {
            // Create a unique address for each user
            address user = address(
                uint160(uint256(keccak256(abi.encodePacked(i))))
            );
            users[i] = user;

            // Assign a unique tokenId to each user
            uint256 tokenId = 1000 + i; // Unique tokenIds for each user
            vm.prank(owner);
            mockPOAP.setTokenOwner(tokenId, user);
            vm.prank(owner);
            mockPOAP.setTokenEvent(tokenId, eventId);

            // Register the user in POAPVerifier
            vm.prank(user);
            poapVerifier.registerUser(user);

            // Fill the batches with some repeated tokenIds
            if (i < 10) {
                tokenIdsBatch1[i] = uint32(tokenId); // First batch: tokenIds 1000-1009
            }
            if (i >= 5 && i < 15) {
                tokenIdsBatch2[i - 5] = uint32(tokenId); // Second batch: tokenIds 1005-1014
            }
        }

        // Finish the registration
        vm.prank(owner);
        poapVerifier.finishRegistration();

        // Verify the first batch of 10 tokenIds
        vm.prank(owner);
        poapVerifier.checkRegisteredUsers(tokenIdsBatch1);

        // Verify the second batch of 10 tokenIds (with some repeated tokenIds)
        vm.prank(owner);
        poapVerifier.checkRegisteredUsers(tokenIdsBatch2);

        // Get the list of verified users
        address[] memory verifiedUsers = poapVerifier.getVerifiedUsers();

        // Verify that there are no duplicate users in verifiedUsers
        for (uint256 i = 0; i < verifiedUsers.length; i++) {
            for (uint256 j = i + 1; j < verifiedUsers.length; j++) {
                assertTrue(
                    verifiedUsers[i] != verifiedUsers[j],
                    "Duplicate user found in verifiedUsers"
                );
            }
        }

        // Verify that the number of verified users is correct
        assertEq(
            verifiedUsers.length,
            15,
            "Incorrect number of verified users"
        );
    }
}
