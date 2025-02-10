// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IPOAP {
    function balanceOf(address account, uint256 id) external view returns (uint256);
}

contract POAPVerifier is Ownable {
    address public poapContract;
    uint256[] public requiredPoapIds;

    mapping(address => bool) public verifiedUsers;
    address[] public verifiedUserList;

    event UserVerified(address indexed user);
    event PoapIdsUpdated(uint256[] newPoapIds);

    constructor(uint256[] memory _initialPoapIds, address _poapContract) Ownable(msg.sender) {
        poapContract = _poapContract;
        requiredPoapIds = _initialPoapIds;
    }

    /**
     * @dev Updates the list of required POAP IDs. Can only be called by the owner.
     * @param _newPoapIds The new array of required POAP IDs.
     */
    function updatePoapIds(uint256[] memory _newPoapIds) public onlyOwner {
        requiredPoapIds = _newPoapIds;
        emit PoapIdsUpdated(_newPoapIds);
    }

    /**
     * @dev Checks if a user holds all required POAPs and registers them if eligible.
     * @param _user The address of the user to verify.
     */
    function checkAndRegister(address _user) public {
        require(!verifiedUsers[_user], "User already verified");
        require(checkEligibility(_user), "User does not have all required POAPs");

        verifiedUsers[_user] = true;
        verifiedUserList.push(_user);
        emit UserVerified(_user);
    }

    /**
     * @dev Checks if a user meets the POAP requirements without registering them.
     * @param _user The address of the user to check.
     * @return true if the user has all required POAPs, false otherwise.
     */
    function checkEligibility(address _user) public view returns (bool) {
        IPOAP poap = IPOAP(poapContract);
        for (uint256 i = 0; i < requiredPoapIds.length; i++) {
            if (poap.balanceOf(_user, requiredPoapIds[i]) == 0) {
                return false;
            }
        }
        return true;
    }

    /**
     * @dev Returns the list of verified users.
     */
    function getVerifiedUsers() public view returns (address[] memory) {
        return verifiedUserList;
    }
}