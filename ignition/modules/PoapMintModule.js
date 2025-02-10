const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

module.exports = buildModule("PoapMintModule", (m) => {
    // Ensure contract address is defined
    if (!process.env.MOCK_POAP_CONTRACT) {
        throw new Error("MOCK_POAP_CONTRACT is not set in environment variables.");
    }

    const mockPoapAddress = process.env.MOCK_POAP_CONTRACT;
    const mockPoap = m.contractAt("MockPOAP", mockPoapAddress);

    // Ensure addresses are defined
    const addresses = [
        process.env.ADDRESS_1,
        process.env.ADDRESS_2,
        process.env.ADDRESS_3,
        process.env.ADDRESS_4
    ];

    if (addresses.some(addr => !addr)) {
        throw new Error("One or more user addresses are not set in environment variables.");
    }

    // Minting POAPs with valid arguments
    m.call(mockPoap, "mint", [addresses[0], 1], { id: "MintAddress1"});
    m.call(mockPoap, "mintBatch", [addresses[1], [1, 2], [1, 1], "0x"], { id: "MintAddress2"});
    m.call(mockPoap, "mintBatch", [addresses[2], [2, 3], [2, 2], "0x"], { id: "MintAddress3"});
    m.call(mockPoap, "mintBatch", [addresses[3], [1, 2, 3, 4], [1, 1, 1, 1], "0x"], { id: "MintAddress4"});

    return {};
});
