// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IPoap.sol";

contract POAPVerifier is Ownable {
    IPOAP public poapContract;
    uint256 public eventId;
    bool public registrationFinished;

    mapping(address => bool) public verifiedUsers;
    mapping(address => bool) public registeredUsers;
    address[] public verifiedUserList;
    address[] public registeredUserList;

    modifier onlyIfNotFinished() {
        require(!registrationFinished, "Registration has already ended");
        _;
    }

    constructor(uint256 _eventId, address _poapContract) Ownable(msg.sender) {
        poapContract = IPOAP(_poapContract);
        eventId = _eventId;
    }

    /**
     * @dev Finish registration process.
     */
    function finishRegistration() external onlyOwner {
        registrationFinished = true;
    }

    /**
     * @dev Check if users have the required POAP and verify them.
     * @param _tokenIds All minted poaps tokenIds for the Sherry eventId.
     */
    function checkRegisteredUsers(
        uint32[] calldata _tokenIds
    ) external onlyOwner {
        require(registrationFinished, "Registration is not finished");

        for (uint32 i = 0; i < _tokenIds.length; i++) {
            uint256 eId = poapContract.tokenEvent(_tokenIds[i]);
            require(eventId == eId, "EventId don't belongs to the Raffle");

            address poapOwner = poapContract.ownerOf(_tokenIds[i]);

            if (registeredUsers[poapOwner] && !verifiedUsers[poapOwner]) {
                verifiedUsers[poapOwner] = true;
                verifiedUserList.push(poapOwner);
            }
        }
    }

    /**
     * @dev Registers the _user for the raffle.
     * @param _user The address of the user that will be registered.
     */
    function registerUser(address _user) external {
        require(!registrationFinished, "Registration has already ended");
        require(!registeredUsers[_user], "User already registered");
        registeredUsers[_user] = true;
        registeredUserList.push(_user);
    }

    /**
     * @dev Returns the list of verified users.
     */
    function getVerifiedUsers() external view returns (address[] memory) {
        return verifiedUserList;
    }

    /**
     * @dev Returns the list of registered users.
     */
    function getRegisteredUsers() external view returns (address[] memory) {
        return registeredUserList;
    }
}
