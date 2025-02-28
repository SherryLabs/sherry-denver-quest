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
    uint16 public usersVerifiedCount = 300;
    // https://docs.chain.link/docs/vrf/v2/supported-networks/#configurations
    bytes32 public keyHash =
        bytes32(
            0x354d2f95da55398f44b7cff77da56283d9c6c829a4bdf1bbcaf2ad6a4d081f61
        ); // fuji
    uint256 public eventId = 1;

    address public owner = address(0xABCD);
    address public user1 = address(0x1);
    address public user2 = address(0x2);
    uint16[5] public winners;

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

    function setUp() public {
        // Deploy VRF
        vrfContract = new VRFCoordinatorV2Mock(0, 0);
        subscriptionId = vrfContract.createSubscription();

        // Deploy Raffle
        raffle = new Raffle(
            address(vrfContract),
            subscriptionId,
            keyHash,
            usersVerifiedCount
        );

        // Transfer ownership to the owner
        vm.prank(address(this));
        raffle.transferOwnership(owner);
    }

    function testSubscriptionCreate() public {
        vm.expectEmit(true, true, false, false);
        emit SubscriptionCreated(2, address(this));
        vrfContract.createSubscription();

        (uint96 balance, uint64 reqCount, address vrfOwner, ) = vrfContract
            .getSubscription(2);

        assertEq(balance, 0);
        assertEq(reqCount, 0);
        assertEq(vrfOwner, address(this));
    }

    function testSubscriptionFund() public {
        vm.expectEmit(true, true, true, false);
        emit SubscriptionFunded(1, 0, 2 ether);
        vrfContract.fundSubscription(1, 2 ether);
    }

    function testAddConsumer() public {
        vm.expectEmit(true, false, false, true);
        emit ConsumerAdded(1, address(raffle));
        vrfContract.addConsumer(1, address(raffle));
    }

    function testRequestIsSent() public {
        vrfContract.fundSubscription(1, 2 ether);
        vrfContract.addConsumer(1, address(raffle));

        vm.prank(owner);
        vm.expectEmit(false, false, false, true);
        emit RandomnessRequested(1);
        raffle.selectWinners();
    }

    function testRequestIsReceived() public {
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
}
