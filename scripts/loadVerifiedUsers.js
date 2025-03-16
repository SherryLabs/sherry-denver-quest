const fs = require('fs');
const path = require('path');
const { ethers } = require('hardhat');

async function main() {
  // Get the Raffle contract
  const Raffle = await ethers.getContractFactory('Raffle');
  
  // Replace with your deployed contract address
  const raffleAddress = '0x'; // TODO: Replace with actual deployed contract address
  const raffle = await Raffle.attach(raffleAddress);
  
  // Read the verified users JSON file
  const verifiedUsersPath = path.join(__dirname, '../verified-users.json');
  const verifiedUsers = JSON.parse(fs.readFileSync(verifiedUsersPath, 'utf8'));
  
  console.log(`Loading ${verifiedUsers.length} verified users to the contract...`);
  
  // Load in batches to avoid gas limits 
  const batchSize = 100;
  for (let i = 0; i < verifiedUsers.length; i += batchSize) {
    const batch = verifiedUsers.slice(i, i + batchSize);
    const tx = await raffle.addVerifiedUsersBatch(batch);
    console.log(`Batch ${Math.floor(i/batchSize) + 1} transaction hash: ${tx.hash}`);
    await tx.wait();
    console.log(`Batch ${Math.floor(i/batchSize) + 1} confirmed. Added ${batch.length} users.`);
  }
  
  const totalUsers = await raffle.getVerifiedUsersCount();
  console.log(`Total verified users in contract: ${totalUsers}`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
