const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

module.exports = buildModule("MockPoapModule", (m) => {
  const mockPoap = m.contract("MockPOAP", []);
  return { mockPoap };
});
