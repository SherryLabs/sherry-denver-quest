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

  // Ensure addresses are defined
  const addresses = [
    process.env.ADDRESS_1,
    process.env.ADDRESS_2,
    process.env.ADDRESS_3,
    process.env.ADDRESS_4,
  ];

  if (addresses.some((addr) => !addr)) {
    throw new Error(
      "One or more user ADDRESSES are not set in environment variables."
    );
  }

  // Minting POAPs with valid arguments
  m.call(mockPoap, "mint", [addresses[0], 1], { id: "MintAddress1" });
  m.call(mockPoap, "mintBatch", [addresses[1], [1, 2], [1, 1], "0x"], {
    id: "MintAddress2",
  });
  m.call(mockPoap, "mintBatch", [addresses[2], [2, 3], [2, 2], "0x"], {
    id: "MintAddress3",
  });
  m.call(
    mockPoap,
    "mintBatch",
    [addresses[3], [1, 2, 3, 4], [1, 1, 1, 1], "0x"],
    { id: "MintAddress4" }
  );

  return {};
});
