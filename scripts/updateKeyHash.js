const hre = require("hardhat");

async function main() {
  try {
    console.log("Starting the key hash update process...");
    
    // Get the deployer account
    const [deployer] = await hre.ethers.getSigners();
    console.log(`Using account: ${deployer.address}`);

    // Get the deployed contract address
    const raffleAddress = '0x83A8A1CFA58AcA9A8e76B657aD6032EA51D474C5';
    console.log(`Connecting to Raffle contract at: ${raffleAddress}`);
    
    // Get the contract factory
    const Raffle = await hre.ethers.getContractFactory("Raffle");
    
    // Connect to the deployed contract
    const raffle = Raffle.attach(raffleAddress);
    console.log("Contract attached successfully");
    
    // Get network information
    const network = await hre.ethers.provider.getNetwork();
    console.log(`Network: ${network.name} (chainId: ${network.chainId})`);
    
    // Check if we're on Avalanche
    const isAvalanche = [43113, 43114].includes(network.chainId);
    if (isAvalanche) {
      console.log(`✓ Detected Avalanche network (${network.chainId === 43114 ? 'C-Chain Mainnet' : 'Fuji Testnet'})`);
    } else {
      console.error("This script is designed for Avalanche networks. Current network is not Avalanche.");
      return;
    }
    
    // Basic checks
    try {
      // Check ownership
      const owner = await raffle.raffleOwner();
      console.log(`Contract owner: ${owner}`);
      
      if (owner.toLowerCase() !== deployer.address.toLowerCase()) {
        console.error(`Error: Deployer (${deployer.address}) is not the contract owner (${owner})`);
        return;
      }
      console.log("✓ Ownership verified");
      
      // Get current key hash
      const currentKeyHash = await raffle.s_keyHash();
      console.log(`Current key hash: ${currentKeyHash}`);
      
      // Show available Avalanche key hash options
      console.log("\nAvailable Avalanche key hash options:");
      console.log("1) 200 gwei Key Hash: 0xea7f56be19583eeb8255aa79f16d8bd8a64cedf68e42fefee1c9ac5372b1a102");
      console.log("2) 500 gwei Key Hash: 0x84213dcadf1f89e4097eb654e3f284d7d5d5bda2bd4748d8b7fada5b3a6eaa0d");
      console.log("3) 1000 gwei Key Hash: 0xe227ebd10a873dde8e58841197a07b410038e405f1180bd117be6f6557fa491c");
      
      // Ask for key hash choice through command line arguments
      const args = process.argv.slice(2);
      let keyHashChoice;
      
      if (args.length > 0 && ['1', '2', '3'].includes(args[0])) {
        keyHashChoice = args[0];
      } else {
        console.error("Please provide a valid key hash choice (1, 2, or 3) as a command line argument");
        console.error("Example: node scripts/updateKeyHash.js 2");
        console.error("\nExplanation of key hash options:");
        console.error("1) 200 gwei - Lowest cost but may take longer");
        console.error("2) 500 gwei - Balanced cost and speed");
        console.error("3) 1000 gwei - Highest cost but fastest response");
        return;
      }
      
      // Map choice to actual key hash
      const keyHashMap = {
        "1": "0xea7f56be19583eeb8255aa79f16d8bd8a64cedf68e42fefee1c9ac5372b1a102", // 200 gwei
        "2": "0x84213dcadf1f89e4097eb654e3f284d7d5d5bda2bd4748d8b7fada5b3a6eaa0d", // 500 gwei
        "3": "0xe227ebd10a873dde8e58841197a07b410038e405f1180bd117be6f6557fa491c"  // 1000 gwei
      };
      
      const newKeyHash = keyHashMap[keyHashChoice];
      const gweiOption = ["200", "500", "1000"][parseInt(keyHashChoice) - 1];
      
      console.log(`\nSelected key hash option ${keyHashChoice} (${gweiOption} gwei):`);
      console.log(newKeyHash);
      
      // Check if key hash is already set to this value
      if (currentKeyHash.toLowerCase() === newKeyHash.toLowerCase()) {
        console.log("The contract is already using this key hash. No update needed.");
        return;
      }
      
      // Update the key hash
      console.log("\nUpdating key hash...");
      const tx = await raffle.updateKeyHash(newKeyHash, { gasLimit: 1000000 });
      console.log(`Transaction submitted! Hash: ${tx.hash}`);
      
      console.log("Waiting for transaction confirmation...");
      const receipt = await tx.wait();
      console.log(`Transaction confirmed in block ${receipt.blockNumber}`);
      
      // Verify the update
      const updatedKeyHash = await raffle.s_keyHash();
      console.log(`\nUpdated key hash: ${updatedKeyHash}`);
      
      if (updatedKeyHash.toLowerCase() === newKeyHash.toLowerCase()) {
        console.log("✅ Key hash successfully updated!");
        console.log(`\nYou can now try to select winners with the new ${gweiOption} gwei key hash.`);
        console.log("This should improve the chances of successful VRF requests.");
      } else {
        console.error("❌ Something went wrong. The key hash was not updated correctly.");
      }
      
    } catch (error) {
      console.error("Error during key hash update:", error);
    }
  } catch (error) {
    console.error("Script error:", error);
  }
}

// Execute the script
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
