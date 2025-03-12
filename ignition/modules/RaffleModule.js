const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");
const fs = require("fs");

function getEnvVariable(name) {
  const value = process.env[name];
  if (!value) {
    throw new Error(`${name} is not defined in the environment variables`);
  }
  return value;
}

module.exports = buildModule("RaffleModule", (m) => {
  let vrfCoordinatorAddress, vrfSubscription, vrfKeyHash, usersVerifiedCount;

  if (process.env.TESTNET == 1) {
    const envVars = {
      vrfCoordinatorAddress: "TESTNET_VRF_COORDINATOR_ADDRESS",
      vrfSubscription: "TESTNET_VRF_SUBSCRIPTION_ID",
      vrfKeyHash: "TESTNET_VRF_KEY_HASH",
      usersVerifiedCount: "TESTNET_POAPVERIFIED_USERS_VERIFIED_COUNT",
    };

    ({
      vrfCoordinatorAddress,
      vrfSubscription,
      vrfKeyHash,
      usersVerifiedCount,
    } = Object.fromEntries(
      Object.entries(envVars).map(([key, envKey]) => [
        key,
        getEnvVariable(envKey),
      ])
    ));
  } else {
    const envVars = {
      vrfCoordinatorAddress: "MAINNET_VRF_COORDINATOR_ADDRESS",
      vrfSubscription: "MAINNET_VRF_SUBSCRIPTION_ID",
      vrfKeyHash: "MAINNET_VRF_KEY_HASH",
      usersVerifiedCount: "MAINNET_POAPVERIFIED_USERS_VERIFIED_COUNT",
    };

    ({
      vrfCoordinatorAddress,
      vrfSubscription,
      vrfKeyHash,
      usersVerifiedCount,
    } = Object.fromEntries(
      Object.entries(envVars).map(([key, envKey]) => [
        key,
        getEnvVariable(envKey),
      ])
    ));
  }

  const content = `module.exports = [
    "${vrfCoordinatorAddress}",
    ${vrfSubscription},
    "${vrfKeyHash}",
    ${usersVerifiedCount},
  ];`;

  fs.writeFileSync("./raffleArgs.js", content, "utf8");
  console.log("Arguments saved to raffleArgs.js");

  const raffle = m.contract("Raffle", [
    vrfCoordinatorAddress,
    vrfSubscription,
    vrfKeyHash,
    usersVerifiedCount,
  ]);

  return { raffle };
});
