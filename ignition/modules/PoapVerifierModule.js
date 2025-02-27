const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");
const fs = require("fs");

module.exports = buildModule("PoapVerifierModule", (m) => {
  let poapContractAddress, deployedAddresses;

  // Check if environment variables are not empty or undefined
  if (process.env.TESTNET == 1) {
    const PATH = `./ignition/deployments/chain-${process.env.CHAIN_ID}/deployed_addresses.json`;;

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
  } else {
    if (process.env.POAP_CONTRACT == "") {
      throw new Error(
        "POAP_CONTRACT is not defined in the environment variables"
      );
    } else {
      poapContractAddress = process.env.POAP_CONTRACT;
    }
  }

  if (!process.env.POAP_EVENT_ID) {
    throw new Error("POAP_EVENT_ID is not defined in the environment variables");
  }

  const poapVerifier = m.contract("POAPVerifier", [
    process.env.POAP_EVENT_ID,
    poapContractAddress,
  ]);

  const content = `module.exports = [
    ${process.env.POAP_EVENT_ID},
    "${poapContractAddress}",
  ];`;

  fs.writeFileSync("./poapVerifierArgs.js", content, "utf8");
  console.log("Arguments saved to poapVerifierArgs.js");

  return { poapVerifier };
});
