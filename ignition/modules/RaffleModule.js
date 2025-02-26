const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");
const fs = require("fs");

module.exports = buildModule("RaffleModule", (m) => {
  let poapVerifierAddress, deployedAddresses;

  // Check if environment variables are not empty or undefined
  const PATH =
    process.env.TESTNET == 1
      ? "./ignition/deployments/chain-44787/deployed_addresses.json"
      : "./ignition/deployments/chain-42220/deployed_addresses.json";

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
