// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

contract Raffle is VRFConsumerBaseV2Plus {
    // Chainlink VRF variables
    uint256 public s_subscriptionId;
    bytes32 public s_keyHash;
    uint32 public callbackGasLimit = 1000000; // Increased for Avalanche - was 500000
    uint16 requestConfirmations = 3;
    uint32 numWords = 5; // select 5 winners
    uint256 public s_requestId;

    // User and winner tracking
    address[] public verifiedUsers;
    address[5] public winners;
    mapping(address => bool) public isVerified;
    mapping(uint16 => uint16) private swappedIndexes; // track swaps

    bool public raffleEnded;
    
    // Custom ownership implementation
    address private _sherryOwner;
    
    event RandomnessRequested(uint256 requestId);
    event VerifiedUserAdded(address user);
    event VerifiedUsersBatchAdded(uint256 count);
    event WinnersSelected(address[5] winners);
    event SherryOwnershipChanged(address indexed previousOwner, address indexed newOwner);
    event KeyHashChanged(bytes32 oldKeyHash, bytes32 newKeyHash);
    event CallbackGasLimitChanged(uint32 oldLimit, uint32 newLimit);

    // Custom modifier that works with our ownership model
    modifier onlySherryOwner() {
        require(_sherryOwner == msg.sender, "Caller is not the sherry owner");
        _;
    }
    
    modifier raffleNotEnded() {
        require(!raffleEnded, "Winners already selected");
        _;
    }

    constructor(
        address vrfCoordinator,
        uint256 subscriptionId,
        bytes32 keyHash
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        s_subscriptionId = subscriptionId;
        s_keyHash = keyHash;
        _sherryOwner = msg.sender;
        emit SherryOwnershipChanged(address(0), msg.sender);
    }
    
    /**
     * @dev Returns the address of the current owner.
     */
    function raffleOwner() public view returns (address) {
        return _sherryOwner;
    }
    
    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function changeSherryOwner(address newOwner) public virtual onlySherryOwner {
        require(newOwner != address(0), "New owner is the zero address");
        address oldOwner = _sherryOwner;
        _sherryOwner = newOwner;
        emit SherryOwnershipChanged(oldOwner, newOwner);
    }
    
    /**
     * @dev Update the key hash used for VRF requests
     * This can be useful if we need to change price tiers or fix configuration issues
     * @param newKeyHash The new key hash to use for VRF requests
     */
    function updateKeyHash(bytes32 newKeyHash) external onlySherryOwner raffleNotEnded {
        require(newKeyHash != 0, "Invalid key hash");
        bytes32 oldKeyHash = s_keyHash;
        s_keyHash = newKeyHash;
        emit KeyHashChanged(oldKeyHash, newKeyHash);
    }
    
    /**
     * @dev Update the callback gas limit for VRF requests
     * This is useful for adjusting gas based on network conditions or request complexity
     * @param newLimit The new callback gas limit to use
     */
    function updateCallbackGasLimit(uint32 newLimit) external onlySherryOwner raffleNotEnded {
        require(newLimit >= 200000, "Gas limit too low");
        require(newLimit <= 5000000, "Gas limit too high");
        
        uint32 oldLimit = callbackGasLimit;
        callbackGasLimit = newLimit;
        emit CallbackGasLimitChanged(oldLimit, newLimit);
    }
    
    /**
     * @dev Add a verified user address to the contract.
     * @param user Address of the verified user.
     */
    function addVerifiedUser(address user) external onlySherryOwner raffleNotEnded {
        require(!isVerified[user], "User already verified");
        verifiedUsers.push(user);
        isVerified[user] = true;
        emit VerifiedUserAdded(user);
    }

    /**
     * @dev Add multiple verified user addresses to the contract.
     * @param users Array of verified user addresses.
     */
    function addVerifiedUsersBatch(
        address[] calldata users
    ) external onlySherryOwner raffleNotEnded {
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
    function selectWinners() external onlySherryOwner raffleNotEnded {
        require(verifiedUsers.length > 5, "Not enough verified users");

        // Request random words 
        s_requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: s_keyHash,
                subId: s_subscriptionId,
                requestConfirmations: requestConfirmations,
                callbackGasLimit: callbackGasLimit,
                numWords: numWords,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            })
        );

        emit RandomnessRequested(s_requestId);
    }

    /**
     * @dev Callback function that Chainlink VRF calls with the random numbers.
     * @param requestId The ID of the request.
     * @param randomWords The random numbers generated.
     */
    function fulfillRandomWords(
        uint256 requestId,
        uint256[] calldata randomWords
    ) internal override raffleNotEnded {
        require(s_requestId == requestId, "Invalid request ID");

        uint16 userCount = uint16(verifiedUsers.length); // Total users
        uint16 available = userCount; // Users left to pick

        for (uint16 i = 0; i < 5; i++) {
            uint16 randIndex = uint16(randomWords[i] % available);

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
        emit WinnersSelected(winners);
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
