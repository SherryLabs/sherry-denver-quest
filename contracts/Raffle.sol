// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "@chainlink/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Raffle is VRFConsumerBaseV2, Ownable {
    // Chainlink VRF variables
    VRFCoordinatorV2Interface public vrfCoordinator;
    uint64 public subscriptionId;
    uint32 callbackGasLimit = 200000;
    uint16 requestConfirmations = 3;
    uint8 numWords = 5; // select 5 winners
    uint16 public usersVerifiedCount;
    bytes32 public keyHash;
    uint256 public requestId;

    // variables to store winners
    bool public raffleEnded;
    uint16[5] public winners;
    mapping(uint16 => uint16) private swappedIndexes; // tack swaps

    event RandomnessRequested(uint256 requestId);

    modifier raffleNotEnded() {
        require(!raffleEnded, "Winners already selected");
        _;
    }

    constructor(
        address _vrfCoordinator,
        uint64 _subscriptionId,
        bytes32 _keyHash,
        uint16 _usersVerifiedCount
    ) VRFConsumerBaseV2(_vrfCoordinator) Ownable(msg.sender) {
        require(_usersVerifiedCount > 5, "Not enough verified users");
        vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinator);
        subscriptionId = _subscriptionId;
        keyHash = _keyHash;
        usersVerifiedCount = _usersVerifiedCount;
    }

    /**
     * @dev Request random numbers from Chainlink VRF to select winners.
     */
    function selectWinners() external onlyOwner raffleNotEnded {
        // Request random numbers from Chainlink VRF
        requestId = vrfCoordinator.requestRandomWords(
            keyHash,
            subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );

        emit RandomnessRequested(requestId);
    }

    /**
     * @dev Callback function that Chainlink VRF calls with the random numbers.
     * @param _requestId The ID of the request.
     * @param _randomWords The random numbers generated.
     */
    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override raffleNotEnded {
        require(requestId == _requestId, "Invalid request ID");

        uint16 userCount = usersVerifiedCount; // Total users
        uint16 available = userCount; // Users left to pick

        for (uint16 i = 0; i < 5; i++) {
            uint16 randIndex = uint16(_randomWords[i] % available);

            // Get actual index (check if it was swapped)
            uint16 selectedIndex = swappedIndexes[randIndex] == 0
                ? randIndex
                : swappedIndexes[randIndex];

            // Store the selected index as a winner
            winners[i] = selectedIndex;

            // Swap selected index with the last available one
            uint16 lastAvailable = available - 1;
            swappedIndexes[randIndex] = swappedIndexes[lastAvailable] == 0
                ? lastAvailable
                : swappedIndexes[lastAvailable];

            available--; // Reduce available range
        }

        raffleEnded = true;
    }


    /**
     * @dev Returns the list of winners.
     */
    function getWinners() external view returns (uint16[5] memory) {
        return winners;
    }
}
