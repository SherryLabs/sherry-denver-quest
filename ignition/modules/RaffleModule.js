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
  let vrfCoordinatorAddress, vrfSubscription, vrfKeyHash;

  if (process.env.TESTNET == 1) {
    const envVars = {
      vrfCoordinatorAddress: "TESTNET_VRF_COORDINATOR_ADDRESS",
      vrfSubscription: "TESTNET_VRF_SUBSCRIPTION_ID",
      vrfKeyHash: "TESTNET_VRF_KEY_HASH",
    };

    ({
      vrfCoordinatorAddress,
      vrfSubscription,
      vrfKeyHash,
    } = Object.fromEntries(
      Object.entries(envVars).map(([key, envKey]) => [
        key,
        getEnvVariable(envKey),
      ])
    ));
  } else {
    vrfCoordinatorAddress = "0xE40895D055bccd2053dD0638C9695E326152b1A4";
    vrfSubscription = BigInt(12633090225496726009155425433359604986029507876510451774952808908792575050921);
    vrfKeyHash = "0xe227ebd10a873dde8e58841197a07b410038e405f1180bd117be6f6557fa491c";
  }

  const content = `module.exports = [
    "${vrfCoordinatorAddress}",
    ${vrfSubscription},
    "${vrfKeyHash}",
  ];`;

  fs.writeFileSync("./raffleArgs.js", content, "utf8");
  console.log("Arguments saved to raffleArgs.js");

  const raffle = m.contract("Raffle", [
    vrfCoordinatorAddress,
    vrfSubscription,
    vrfKeyHash,
  ]);

  return { raffle };
});
