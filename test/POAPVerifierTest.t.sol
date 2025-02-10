// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Test.sol";
import "../contracts/MockPOAP.sol";
import "../contracts/POAPVerifier.sol";

contract POAPVerifierTest is Test {
    MockPOAP mockPoap;
    POAPVerifier poapVerifier;
    address owner = address(this);
    address addr1 = address(0x1);
    address addr2 = address(0x2);
    address addr3 = address(0x3);
    address addr4 = address(0x4);

    function setUp() public {
        // Deploy a mock POAP contract
        mockPoap = new MockPOAP();

        // Declare a dynamic uint256 array in memory
        uint256[] memory poapIds = new uint256[](4);
        poapIds[0] = 1;
        poapIds[1] = 2;
        poapIds[2] = 3;
        poapIds[3] = 4;

        // Deploy the POAPVerifier contract with the correctly formatted array
        poapVerifier = new POAPVerifier(poapIds, address(mockPoap));
    }

    function testMintPoaps() public {
        // Mint POAPs to different addresses and verify balances

        // Address 1 receives 1 type of POAP
        mockPoap.mint(addr1, 1);
        assertEq(mockPoap.balanceOf(addr1, 1), 1);

        // Address 2 receives 2 types of POAPs
        mockPoap.mint(addr2, 1);
        mockPoap.mint(addr2, 2);
        assertEq(mockPoap.balanceOf(addr2, 1), 1);
        assertEq(mockPoap.balanceOf(addr2, 2), 1);

        // Address 3 receives 2 types of POAPs, 2 of each
        uint256[] memory ids = new uint256[](2);
        ids[0] = 2;
        ids[1] = 3;
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 2;
        amounts[1] = 2;
        mockPoap.mintBatch(addr3, ids, amounts, "");

        assertEq(mockPoap.balanceOf(addr3, 2), 2);
        assertEq(mockPoap.balanceOf(addr3, 3), 2);

        // Address 4 receives 4 different POAPs
        uint256[] memory allIds = new uint256[](4);
        allIds[0] = 1;
        allIds[1] = 2;
        allIds[2] = 3;
        allIds[3] = 4;
        uint256[] memory allAmounts = new uint256[](4);
        allAmounts[0] = 1;
        allAmounts[1] = 1;
        allAmounts[2] = 1;
        allAmounts[3] = 1;
        mockPoap.mintBatch(addr4, allIds, allAmounts, "");

        assertEq(mockPoap.balanceOf(addr4, 1), 1);
        assertEq(mockPoap.balanceOf(addr4, 2), 1);
        assertEq(mockPoap.balanceOf(addr4, 3), 1);
        assertEq(mockPoap.balanceOf(addr4, 4), 1);
    }

    function testVerifyUsers() public {
        // Mint all required POAPs to addr4 to make them eligible
        uint256[] memory ids = new uint256[](4);
        ids[0] = 1;
        ids[1] = 2;
        ids[2] = 3;
        ids[3] = 4;
        uint256[] memory amounts = new uint256[](4);
        amounts[0] = 1;
        amounts[1] = 1;
        amounts[2] = 1;
        amounts[3] = 1;
        mockPoap.mintBatch(addr4, ids, amounts, "");

        // The user should pass the verification
        poapVerifier.checkAndRegister(addr4);
        assertTrue(poapVerifier.verifiedUsers(addr4));

        // Address 1 does not have all required POAPs, should revert
        vm.expectRevert("User does not have all required POAPs");
        poapVerifier.checkAndRegister(addr1);
    }

    function testCannotRegisterTwice() public {
        // Mint all required POAPs to addr4
        uint256[] memory ids = new uint256[](4);
        ids[0] = 1;
        ids[1] = 2;
        ids[2] = 3;
        ids[3] = 4;
        uint256[] memory amounts = new uint256[](4);
        amounts[0] = 1;
        amounts[1] = 1;
        amounts[2] = 1;
        amounts[3] = 1;
        mockPoap.mintBatch(addr4, ids, amounts, "");

        // First registration should succeed
        poapVerifier.checkAndRegister(addr4);

        // Second registration should revert
        vm.expectRevert("User already verified");
        poapVerifier.checkAndRegister(addr4);
    }

    function testOnlyOwnerCanUpdatePoaps() public {
        // Only the owner should be able to update the required POAP IDs
        uint256[] memory newPoaps = new uint256[](2);
        newPoaps[0] = 1;
        newPoaps[1] = 3;
        poapVerifier.updatePoapIds(newPoaps);

        // A non-owner should not be able to update POAP IDs
        vm.prank(addr1);
        vm.expectRevert();
        poapVerifier.updatePoapIds(newPoaps);
    }
}
