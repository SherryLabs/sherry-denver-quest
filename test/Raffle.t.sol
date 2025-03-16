// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Test.sol";
import "../contracts/Raffle.sol";
import "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2Mock.sol";

contract RaffleTest is Test {
    Raffle public raffle;
    // https://docs.chain.link/docs/vrf/v2/supported-networks/#configurations
    VRFCoordinatorV2Mock public vrfContract; // Mock VRFCoordinator
    uint64 public subscriptionId;
    // https://docs.chain.link/docs/vrf/v2/supported-networks/#configurations
    bytes32 public keyHash =
        bytes32(
            0x354d2f95da55398f44b7cff77da56283d9c6c829a4bdf1bbcaf2ad6a4d081f61
        ); // fuji
    uint256 public eventId = 1;

    address public owner = address(0xABCD);
    address public user1 = address(0x1);
    address public user2 = address(0x2);
    address public user3 = address(0x3);
    address public user4 = address(0x4);
    address public user5 = address(0x5);
    address public user6 = address(0x6);
    address[5] public winners;

    // Mock addresses for testing
    address[] public testAddresses;

    event SubscriptionCreated(uint64 indexed subId, address owner);
    event SubscriptionFunded(
        uint64 indexed subId,
        uint256 oldBalance,
        uint256 newBalance
    );
    event ConsumerAdded(uint64 indexed subId, address consumer);
    event RandomWordsRequested(
        bytes32 indexed keyHash,
        uint256 requestId,
        uint256 preSeed,
        uint64 indexed subId,
        uint16 minimumRequestConfirmations,
        uint32 callbackGasLimit,
        uint32 numWords,
        address indexed sender
    );
    event RandomWordsFulfilled(
        uint256 indexed requestId,
        uint256 outputSeed,
        uint96 payment,
        bool success
    );

    event RandomnessRequested(uint256 requestId);
    event VerifiedUserAdded(address user);
    event VerifiedUsersBatchAdded(uint256 count);
    event SherryOwnershipChanged(address indexed previousOwner, address indexed newOwner); // Updated event

    function setUp() public {
        // Deploy VRF
        vrfContract = new VRFCoordinatorV2Mock(0, 0);
        subscriptionId = vrfContract.createSubscription();

        // Deploy Raffle
        raffle = new Raffle(
            address(vrfContract),
            subscriptionId,
            keyHash
        );

        // Transfer ownership to the owner
        vm.prank(address(this));
        raffle.changeSherryOwner(owner); // Updated function name

        // Create test addresses
        for (uint i = 0; i < 10; i++) {
            testAddresses.push(address(uint160(0x1000 + i)));
        }
    }

    function testAddVerifiedUser() public {
        vm.prank(owner);
        vm.expectEmit(false, false, false, true);
        emit VerifiedUserAdded(user1);
        raffle.addVerifiedUser(user1);
        
        bool isVerified = raffle.isVerified(user1);
        assertTrue(isVerified, "User should be verified");
        
        uint256 count = raffle.getVerifiedUsersCount();
        assertEq(count, 1, "Should have 1 verified user");
    }
    
    function testAddDuplicateUser() public {
        vm.prank(owner);
        raffle.addVerifiedUser(user1);
        
        vm.prank(owner);
        vm.expectRevert("User already verified");
        raffle.addVerifiedUser(user1);
    }
    
    function testAddVerifiedUsersBatch() public {
        address[] memory users = new address[](3);
        users[0] = user1;
        users[1] = user2;
        users[2] = user3;
        
        vm.prank(owner);
        vm.expectEmit(false, false, false, true);
        emit VerifiedUsersBatchAdded(3);
        raffle.addVerifiedUsersBatch(users);
        
        uint256 count = raffle.getVerifiedUsersCount();
        assertEq(count, 3, "Should have 3 verified users");
        
        bool isUser1Verified = raffle.isVerified(user1);
        bool isUser2Verified = raffle.isVerified(user2);
        bool isUser3Verified = raffle.isVerified(user3);
        
        assertTrue(isUser1Verified && isUser2Verified && isUser3Verified, "All users should be verified");
    }
    
    function testAddVerifiedUsersBatchWithDuplicates() public {
        // Add user1 first
        vm.prank(owner);
        raffle.addVerifiedUser(user1);
        
        // Try to add user1 again in a batch
        address[] memory users = new address[](3);
        users[0] = user1;  // duplicate
        users[1] = user2;
        users[2] = user3;
        
        vm.prank(owner);
        raffle.addVerifiedUsersBatch(users);
        
        uint256 count = raffle.getVerifiedUsersCount();
        assertEq(count, 3, "Should have 3 verified users (no duplicates)");
    }
    
    function testGetAllVerifiedUsers() public {
        vm.startPrank(owner);
        raffle.addVerifiedUser(user1);
        raffle.addVerifiedUser(user2);
        vm.stopPrank();
        
        address[] memory users = raffle.getAllVerifiedUsers();
        assertEq(users.length, 2, "Should return 2 users");
        assertEq(users[0], user1, "First user should be user1");
        assertEq(users[1], user2, "Second user should be user2");
    }

    function testNotEnoughVerifiedUsers() public {
        vm.prank(owner);
        raffle.addVerifiedUser(user1);
        
        vm.prank(owner);
        vm.expectRevert("Not enough verified users");
        raffle.selectWinners();
    }

    function testRequestIsSent() public {
        // Add enough verified users
        vm.startPrank(owner);
        raffle.addVerifiedUser(user1);
        raffle.addVerifiedUser(user2);
        raffle.addVerifiedUser(user3);
        raffle.addVerifiedUser(user4);
        raffle.addVerifiedUser(user5);
        raffle.addVerifiedUser(user6);
        vm.stopPrank();
        
        vrfContract.fundSubscription(1, 2 ether);
        vrfContract.addConsumer(1, address(raffle));

        vm.prank(owner);
        vm.expectEmit(false, false, false, true);
        emit RandomnessRequested(1);
        raffle.selectWinners();
    }

    function testRequestIsReceived() public {
        // Add enough verified users
        vm.startPrank(owner);
        for (uint i = 0; i < 6; i++) {
            raffle.addVerifiedUser(testAddresses[i]);
        }
        vm.stopPrank();
        
        vrfContract.fundSubscription(1, 2 ether);
        vrfContract.addConsumer(1, address(raffle));

        vm.prank(owner);
        vm.expectEmit(true, true, true, false);
        emit RandomWordsRequested(
            bytes32(
                0x354d2f95da55398f44b7cff77da56283d9c6c829a4bdf1bbcaf2ad6a4d081f61
            ),
            1,
            100,
            1,
            0,
            0,
            5,
            address(raffle)
        );
        raffle.selectWinners();
    }

    function testRequestIsProcessed() public {
        // Add enough verified users
        vm.startPrank(owner);
        for (uint i = 0; i < 6; i++) {
            raffle.addVerifiedUser(testAddresses[i]);
        }
        vm.stopPrank();
        
        vrfContract.fundSubscription(1, 2 ether);
        vrfContract.addConsumer(1, address(raffle));

        vm.prank(owner);
        raffle.selectWinners();

        vm.expectEmit(true, false, false, true);
        emit RandomWordsFulfilled(1, 1, 0, true);
        vrfContract.fulfillRandomWords(1, address(raffle));
    }

    function testValidRequestIs() public {
        // Add enough verified users
        vm.startPrank(owner);
        for (uint i = 0; i < 6; i++) {
            raffle.addVerifiedUser(testAddresses[i]);
        }
        vm.stopPrank();
        
        vrfContract.fundSubscription(1, 2 ether);
        vrfContract.addConsumer(1, address(raffle));

        vm.prank(owner);
        raffle.selectWinners();

        vm.expectRevert("nonexistent request");
        vrfContract.fulfillRandomWords(2, address(raffle));
    }

    function testResponseIsReceived() public {
        // Add enough verified users
        vm.startPrank(owner);
        for (uint i = 0; i < 10; i++) {
            raffle.addVerifiedUser(testAddresses[i]);
        }
        vm.stopPrank();
        
        vrfContract.fundSubscription(1, 2 ether);
        vrfContract.addConsumer(1, address(raffle));

        vm.prank(owner);
        raffle.selectWinners();

        vm.expectEmit(false, false, false, true);
        emit RandomWordsFulfilled(1, 1, 0, true);
        vrfContract.fulfillRandomWords(1, address(raffle));

        bool raffleEnded = raffle.raffleEnded();
        assertTrue(raffleEnded, "Raffle should be ended");
        winners = raffle.getWinners();

        bool allZeroes = true;
        for (uint256 i = 0; i < 5; i++) {
            if (winners[i] != address(0)) {
                allZeroes = false;
                break;
            }
        }
        assertFalse(allZeroes, "getWinners() should not return all zero addresses");
    }

    function testWinnersNoDuplicates() public {
        // Add enough verified users
        vm.startPrank(owner);
        for (uint i = 0; i < 10; i++) {
            raffle.addVerifiedUser(testAddresses[i]);
        }
        vm.stopPrank();
        
        vrfContract.fundSubscription(1, 2 ether);
        vrfContract.addConsumer(1, address(raffle));

        vm.prank(owner);
        raffle.selectWinners();

        vm.expectEmit(false, false, false, true);
        emit RandomWordsFulfilled(1, 1, 0, true);
        vrfContract.fulfillRandomWords(1, address(raffle));

        winners = raffle.getWinners();

        for (uint256 i = 0; i < 5; i++) {
            for (uint256 j = i + 1; j < 5; j++) {
                if (winners[i] == winners[j] && winners[i] != address(0)) {
                    revert("getWinners() should not have duplicate addresses");
                }
            }
        }
    }

    function testDoubleResponseIsReceived() public {
        // Add enough verified users
        vm.startPrank(owner);
        for (uint i = 0; i < 10; i++) {
            raffle.addVerifiedUser(testAddresses[i]);
        }
        vm.stopPrank();
        
        vrfContract.fundSubscription(1, 2 ether);
        vrfContract.addConsumer(1, address(raffle));

        vm.prank(owner);
        raffle.selectWinners();

        vm.expectEmit(false, false, false, true);
        emit RandomWordsFulfilled(1, 1, 0, true);
        vrfContract.fulfillRandomWords(1, address(raffle));

        vm.expectRevert("nonexistent request");
        vrfContract.fulfillRandomWords(1, address(raffle));
    }

    function testSelectWinnersAfterRaffleEnded() public {
        // Add enough verified users
        vm.startPrank(owner);
        for (uint i = 0; i < 10; i++) {
            raffle.addVerifiedUser(testAddresses[i]);
        }
        vm.stopPrank();
        
        vrfContract.fundSubscription(1, 2 ether);
        vrfContract.addConsumer(1, address(raffle));

        vm.prank(owner);
        raffle.selectWinners();

        vm.expectEmit(false, false, false, true);
        emit RandomWordsFulfilled(1, 1, 0, true);
        vrfContract.fulfillRandomWords(1, address(raffle));

        vm.prank(owner);
        vm.expectRevert("Winners already selected");
        raffle.selectWinners();
    }
    
    function testAddVerifiedUserAfterRaffleEnded() public {
        // Add enough verified users
        vm.startPrank(owner);
        for (uint i = 0; i < 10; i++) {
            raffle.addVerifiedUser(testAddresses[i]);
        }
        vm.stopPrank();
        
        vrfContract.fundSubscription(1, 2 ether);
        vrfContract.addConsumer(1, address(raffle));

        vm.prank(owner);
        raffle.selectWinners();
        vrfContract.fulfillRandomWords(1, address(raffle));
        
        vm.prank(owner);
        vm.expectRevert("Winners already selected");
        raffle.addVerifiedUser(user1);
    }
}
