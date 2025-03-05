const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");
const fs = require("fs");

module.exports = buildModule("RaffleModule", (m) => {
  let poapVerifierAddress, deployedAddresses;

  const PATH = `./ignition/deployments/chain-${process.env.CHAIN_ID}/deployed_addresses.json`;

  // Check if POAPVerifier is already deployed
  if (fs.existsSync(PATH)) {
    deployedAddresses = JSON.parse(fs.readFileSync(PATH, "utf8"));
    if (!deployedAddresses["PoapVerifierModule#POAPVerifier"]) {
      throw new Error("POAPVerifierContract is not deployed yet");
    } else {
      poapVerifierAddress =
        deployedAddresses["PoapVerifierModule#POAPVerifier"];
    }
  } else {
    throw new Error("POAPVerifierContract is not deployed yet");
  }

  const raffle = m.contract("Raffle", poapVerifierAddress);

  return { raffle };
});
