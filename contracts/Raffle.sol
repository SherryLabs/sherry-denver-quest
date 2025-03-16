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
    bytes32 public keyHash;
    uint256 public requestId;

    // User and winner tracking
    address[] public verifiedUsers;
    address[5] public winners;
    mapping(address => bool) public isVerified;
    mapping(uint16 => uint16) private swappedIndexes; // track swaps

    bool public raffleEnded;

    event RandomnessRequested(uint256 requestId);
    event VerifiedUserAdded(address user);
    event VerifiedUsersBatchAdded(uint256 count);

    modifier raffleNotEnded() {
        require(!raffleEnded, "Winners already selected");
        _;
    }

    constructor(
        address _vrfCoordinator,
        uint64 _subscriptionId,
        bytes32 _keyHash
    ) VRFConsumerBaseV2(_vrfCoordinator) Ownable(msg.sender) {
        vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinator);
        subscriptionId = _subscriptionId;
        keyHash = _keyHash;
    }

    /**
     * @dev Add a verified user address to the contract.
     * @param user Address of the verified user.
     */
    function addVerifiedUser(address user) external onlyOwner raffleNotEnded {
        require(!isVerified[user], "User already verified");
        verifiedUsers.push(user);
        isVerified[user] = true;
        emit VerifiedUserAdded(user);
    }

    /**
     * @dev Add multiple verified user addresses to the contract.
     * @param users Array of verified user addresses.
     */
    function addVerifiedUsersBatch(address[] calldata users) external onlyOwner raffleNotEnded {
        for (uint i = 0; i < users.length; i++) {
            if (!isVerified[users[i]]) {
                verifiedUsers.push(users[i]);
                isVerified[users[i]] = true;
            }
        }
        emit VerifiedUsersBatchAdded(users.length);
    }

    /**
     * @dev Request random numbers from Chainlink VRF to select winners.
     */
    function selectWinners() external onlyOwner raffleNotEnded {
        require(verifiedUsers.length > 5, "Not enough verified users");
        
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

        uint16 userCount = uint16(verifiedUsers.length); // Total users
        uint16 available = userCount; // Users left to pick

        for (uint16 i = 0; i < 5; i++) {
            uint16 randIndex = uint16(_randomWords[i] % available);

            // Get actual index (check if it was swapped)
            uint16 selectedIndex = swappedIndexes[randIndex] == 0
                ? randIndex
                : swappedIndexes[randIndex];

            // Store the selected user address as a winner
            winners[i] = verifiedUsers[selectedIndex];

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
     * @dev Returns the list of winner addresses.
     */
    function getWinners() external view returns (address[5] memory) {
        return winners;
    }
    
    /**
     * @dev Returns the total number of verified users.
     */
    function getVerifiedUsersCount() external view returns (uint256) {
        return verifiedUsers.length;
    }
    
    /**
     * @dev Check if an address is a verified user.
     */
    function isUserVerified(address user) external view returns (bool) {
        return isVerified[user];
    }
    
    /**
     * @dev Returns all verified user addresses.
     */
    function getAllVerifiedUsers() external view returns (address[] memory) {
        return verifiedUsers;
    }
}
