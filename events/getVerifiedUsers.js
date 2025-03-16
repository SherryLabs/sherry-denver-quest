const { ethers } = require("ethers");
const fs = require("fs");

const REGISTERED_USERS_FILE = "verified-users.json";
const contractAbi = [
  "function getVerifiedUsers() view returns (address[])"
];
const provider = new ethers.JsonRpcProvider("https://forno.celo.org");
const contractAddress = "0x3449afc2fCF3D51DC892658f0c69E47286B078d4"; // Sherry POAP Verifier Contract
const contract = new ethers.Contract(contractAddress, contractAbi, provider);

async function fetchAndStoreRegisteredUsers() {
  try {
    const registeredUsers = await contract.getVerifiedUsers();
    fs.writeFileSync(
      REGISTERED_USERS_FILE,
      JSON.stringify(registeredUsers, null, 2)
    );
    console.log(`verified users stored in: ${REGISTERED_USERS_FILE}`);
  } catch (error) {
    console.error("Error fetching verified users:", error);
  }
}

fetchAndStoreRegisteredUsers();
