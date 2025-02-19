const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");
const fs = require("fs");

module.exports = buildModule("PoapMintModule", (m) => {
  let poapContractAddress, deployedAddresses;

  // Check if environment variables are not empty or undefined
  const PATH = "./ignition/deployments/chain-44787/deployed_addresses.json";

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

  const mockPoap = m.contractAt("MockPOAP", poapContractAddress);

  // Minting POAPs with valid arguments
  m.call(mockPoap, "mint", [process.env.TEST_ADDRESS, 1], { id: "MintAddress1" });

  return {};
});
