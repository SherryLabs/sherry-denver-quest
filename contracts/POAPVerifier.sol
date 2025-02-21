// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IPOAP {
    function balanceOf(
        address account,
        uint256 id
    ) external view returns (uint256);
}

contract POAPVerifier is Ownable {
    address public poapContract;
    uint256 public poapId;
    bool public registrationFinished;

    mapping(address => bool) public verifiedUsers;
    address[] public verifiedUserList;

    event UserVerified(address indexed user);

    modifier onlyIfNotFinished() {
        require(!registrationFinished, "Registration has already ended");
        _;
    }

    constructor(uint256 _poapId, address _poapContract) Ownable(msg.sender) {
        poapContract = _poapContract;
        poapId = _poapId;
    }

    /**
     * @dev Checks if a user holds the required POAP and registers them.
     * @param _user The address of the user to verify.
     */
    function checkAndRegister(address _user) public onlyIfNotFinished {
        require(!verifiedUsers[_user], "User already verified");
        require(
            checkEligibility(_user),
            "User does not have the required POAP"
        );

        verifiedUserList.push(_user);
        verifiedUsers[_user] = true;

        emit UserVerified(_user);
    }

    /**
     * @dev Checks if a user has the POAP required without registering them.
     * @param _user The address of the user to check.
     * @return true if the user has all required POAPs, false otherwise.
     */
    function checkEligibility(address _user) public view returns (bool) {
        IPOAP poap = IPOAP(poapContract);
        return poap.balanceOf(_user, poapId) > 0;
    }

    /**
     * @dev Returns the list of verified users.
     */
    function getVerifiedUsers() public view returns (address[] memory) {
        return verifiedUserList;
    }
}
