// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "@chainlink/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./POAPVerifier.sol";

contract Raffle is VRFConsumerBaseV2, Ownable {
    // POAPVerifier contract address
    POAPVerifier public poapVerifier;

    // Chainlink VRF variables
    VRFCoordinatorV2Interface public vrfCoordinator;
    uint64 public subscriptionId;
    bytes32 public keyHash;
    uint32 public callbackGasLimit = 100000;
    uint16 public requestConfirmations = 3;
    uint8 public numWords = 5; // select 5 winners
    uint256 public requestId;

    // variables to store winners
    address[] public winners;
    mapping(address => bool) public isWinner;

    event WinnersSelected(address[] winners);
    event RandomnessRequested(uint256 requestId);

    constructor(
        address _poapVerifier,
        address _vrfCoordinator,
        uint64 _subscriptionId,
        bytes32 _keyHash
    ) VRFConsumerBaseV2(_vrfCoordinator) Ownable(msg.sender) {
        poapVerifier = POAPVerifier(_poapVerifier);
        vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinator);
        subscriptionId = _subscriptionId;
        keyHash = _keyHash;
    }

    /**
     * @dev Request random numbers from Chainlink VRF to select winners.
     */
    function selectWinners() external onlyOwner {
        require(winners.length == 0, "Winners already selected");

        // Get the list of verified users
        address[] memory verifiedUsers = poapVerifier.getVerifiedUsers();
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
    ) internal override {
        require(requestId == _requestId, "Invalid request ID");

        address[] memory verifiedUsers = poapVerifier.getVerifiedUsers();
        uint256 userCount = verifiedUsers.length;

        for (uint256 i = 0; i < numWords; i++) {
            uint256 randomIndex = _randomWords[i] % (userCount - i);
            address winner = verifiedUsers[randomIndex];

            // Swap to avoid selecting the same index again (Fisher-Yates shuffle)
            (verifiedUsers[randomIndex], verifiedUsers[userCount - i - 1]) = (
                verifiedUsers[userCount - i - 1],
                verifiedUsers[randomIndex]
            );

            winners.push(winner);
            isWinner[winner] = true;
        }

        emit WinnersSelected(winners);
    }

    /**
     * @dev Devuelve la lista de ganadores.
     */
    function getWinners() external view returns (address[] memory) {
        return winners;
    }
}
