const fs = require('fs');
const path = require('path');
const { ethers } = require('hardhat');

async function main() {
  // Get the deployer account (should be the owner of the contract)
  const [deployer] = await ethers.getSigners();
  console.log(`Using account: ${deployer.address}`);

  // Get the Raffle contract
  const Raffle = await ethers.getContractFactory('Raffle');
  
  // Replace with your deployed contract address
  const raffleAddress = '0x2e3b71cF183657582F03c44F35fECF235677C1ED'; 
  const raffle = await Raffle.attach(raffleAddress).connect(deployer);
  
  // Verify the deployer is the owner
  try {
    const owner = await raffle.raffleOwner();
    console.log(`Contract owner: ${owner}`);
    
    if (owner.toLowerCase() !== deployer.address.toLowerCase()) {
      console.error(`Error: Deployer (${deployer.address}) is not the contract owner (${owner})`);
      return;
    }
  } catch (error) {
    console.error('Error checking contract ownership:', error);
    return;
  }
  
  // Read the verified users JSON file
  const verifiedUsersPath = path.join(__dirname, '../verified-users.json');
  const verifiedUsers = JSON.parse(fs.readFileSync(verifiedUsersPath, 'utf8'));
  
  console.log(`Loading ${verifiedUsers.length} verified users to the contract...`);
  
  // Check if users are already verified before adding them
  const usersToAdd = [];
  for (const user of verifiedUsers) {
    try {
      const isVerified = await raffle.isUserVerified(user);
      if (!isVerified) {
        usersToAdd.push(user);
      }
    } catch (error) {
      console.error(`Error checking if user ${user} is verified:`, error);
    }
  }
  
  console.log(`${usersToAdd.length} users need to be added to the contract`);
  
  if (usersToAdd.length === 0) {
    console.log('No new users to add. Exiting.');
    return;
  }
  
  // Load in batches to avoid gas limits
  const batchSize = 50; // Reduced batch size for better reliability
  for (let i = 0; i < usersToAdd.length; i += batchSize) {
    const batch = usersToAdd.slice(i, i + batchSize);
    console.log(`Submitting batch ${Math.floor(i/batchSize) + 1} with ${batch.length} users...`);
    
    try {
      // Estimate gas for the transaction to ensure it will succeed
      const gasEstimate = await raffle.estimateGas.addVerifiedUsersBatch(batch);
      console.log(`Gas estimate for batch: ${gasEstimate.toString()}`);
      
      // Add 20% buffer to gas estimate
      const gasLimit = gasEstimate.mul(120).div(100);
      
      const tx = await raffle.addVerifiedUsersBatch(batch, { gasLimit });
      console.log(`Batch ${Math.floor(i/batchSize) + 1} transaction hash: ${tx.hash}`);
      
      const receipt = await tx.wait();
      console.log(`Batch ${Math.floor(i/batchSize) + 1} confirmed. Gas used: ${receipt.gasUsed.toString()}`);
    } catch (error) {
      console.error(`Error adding batch ${Math.floor(i/batchSize) + 1}:`, error);
      // If there's an error, try to add users one by one
      console.log('Trying to add users one by one...');
      for (const user of batch) {
        try {
          const isVerified = await raffle.isUserVerified(user);
          if (!isVerified) {
            const tx = await raffle.addVerifiedUser(user);
            await tx.wait();
            console.log(`Successfully added user ${user}`);
          }
        } catch (userError) {
          console.error(`Failed to add user ${user}:`, userError.message);
        }
      }
    }
  }
  
  try {
    const totalUsers = await raffle.getVerifiedUsersCount();
    console.log(`Total verified users in contract: ${totalUsers}`);
  } catch (error) {
    console.error('Error getting verified users count:', error);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
