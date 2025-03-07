const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");
const fs = require("fs");

module.exports = buildModule("PoapMintModule", (m) => {
  let poapContractAddress, deployedAddresses;

  const PATH = `./ignition/deployments/chain-${process.env.CHAIN_ID}/deployed_addresses.json`;

  // Check if MockPoap is already deployed
  if (fs.existsSync(PATH)) {
    deployedAddresses = JSON.parse(fs.readFileSync(PATH, "utf8"));
    if (!deployedAddresses["MockPoapModule#MockPOAP"]) {
      throw new Error("MockPoapContract is not deployed yet");
    } else {
      poapContractAddress = deployedAddresses["MockPoapModule#MockPOAP"];
    }
  } else {
    throw new Error("MockPoapContract is not deployed yet");
  }

  if (!process.env.POAP_EVENT_ID) {
    throw new Error(
      "POAP_EVENT_ID is not defined in the environment variables"
    );
  }

  const mockPoap = m.contractAt("MockPOAP", poapContractAddress);

  // Minting POAPs with valid arguments
  m.call(mockPoap, "setTokenOwner", [1, process.env.TESTNET_ADDRESS], {
    id: "setTokenOwner",
  });
  m.call(mockPoap, "setTokenEvent", [1, process.env.POAP_EVENT_ID], {
    id: "setTokenEvent",
  });

  return {};
});
