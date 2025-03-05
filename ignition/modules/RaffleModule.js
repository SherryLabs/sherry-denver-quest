const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

module.exports = buildModule("RaffleModule", (m) => {

  const raffle = m.contract("Raffle", poapVerifierAddress);

  return { raffle };
});
