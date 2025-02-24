const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

module.exports = buildModule("RaffleModule", (m) => {
  if (!process.env.USER_REGISTERED_COUNT) {
    throw new Error(
      "USER_REGISTERED_COUNT is not defined in the environment variables"
    );
  }

  const raffle = m.contract("Raffle", [process.env.USER_REGISTERED_COUNT]);

  return { raffle };
});
