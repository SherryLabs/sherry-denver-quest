const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

module.exports = buildModule("PoapVerifierModule", (m) => {
    // Check if MOCK_POAP_CONTRACT is not empty or undefined
    if (!process.env.MOCK_POAP_CONTRACT) {
        throw new Error("MOCK_POAP_CONTRACT is not defined in the environment variables");
    }

    // If the variable is defined, proceed with deployment
    const requiredPoapIds = [1, 2, 3, 4]; // Sample POAP IDs
    const poapVerifier = m.contract("POAPVerifier", [requiredPoapIds, process.env.MOCK_POAP_CONTRACT]);

    return { poapVerifier };
});
