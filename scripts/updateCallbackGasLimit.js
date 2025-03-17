const hre = require("hardhat");

async function main() {
  try {
    console.log("Starting the callback gas limit update process...");
    
    // Get the deployer account
    const [deployer] = await hre.ethers.getSigners();
    console.log(`Using account: ${deployer.address}`);

    // Get the deployed contract address
    const raffleAddress = '0x2e3b71cF183657582F03c44F35fECF235677C1ED';
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
      
      // Get current gas limit
      const currentGasLimit = await raffle.callbackGasLimit();
      console.log(`Current callback gas limit: ${currentGasLimit}`);
      
      // Show recommended gas limits for Avalanche
      console.log("\nRecommended gas limits for VRF callback:");
      console.log("1) 1,000,000 - Standard (default)");
      console.log("2) 1,500,000 - Higher (for complex operations)");
      console.log("3) 2,000,000 - Maximum (for very complex operations)");
      console.log("4) Custom value");
      
      // Ask for gas limit choice through command line arguments
      const args = process.argv.slice(2);
      let gasLimitChoice;
      let newGasLimit;
      
      if (args.length > 0) {
        if (['1', '2', '3'].includes(args[0])) {
          gasLimitChoice = args[0];
          // Map choice to actual gas limit
          const gasLimitMap = {
            "1": 1000000,
            "2": 1500000,
            "3": 2000000
          };
          newGasLimit = gasLimitMap[gasLimitChoice];
        } else {
          // Try to parse as a custom value
          try {
            const customGas = parseInt(args[0]);
            if (customGas >= 200000 && customGas <= 5000000) {
              newGasLimit = customGas;
              gasLimitChoice = "4";
            } else {
              throw new Error("Invalid gas limit range");
            }
          } catch {
            console.error("Invalid gas limit format");
            return;
          }
        }
      } else {
        console.error("Please provide a valid gas limit choice (1-4) or a custom value as a command line argument");
        console.error("Example: node scripts/updateCallbackGasLimit.js 2");
        console.error("Or for a custom value: node scripts/updateCallbackGasLimit.js 1750000");
        return;
      }
      
      // Show selected gas limit
      console.log(`\nSelected gas limit option ${gasLimitChoice}: ${newGasLimit} gas units`);
      
      // Check if gas limit is already set to this value
      if (currentGasLimit == newGasLimit) {
        console.log("The contract is already using this callback gas limit. No update needed.");
        return;
      }
      
      // Update the gas limit
      console.log("\nUpdating callback gas limit...");
      const tx = await raffle.updateCallbackGasLimit(newGasLimit, { gasLimit: 500000 });
      console.log(`Transaction submitted! Hash: ${tx.hash}`);
      
      console.log("Waiting for transaction confirmation...");
      const receipt = await tx.wait();
      console.log(`Transaction confirmed in block ${receipt.blockNumber}`);
      
      // Verify the update
      const updatedGasLimit = await raffle.callbackGasLimit();
      console.log(`\nUpdated callback gas limit: ${updatedGasLimit}`);
      
      if (updatedGasLimit == newGasLimit) {
        console.log("✅ Callback gas limit successfully updated!");
        console.log(`\nYou can now try to select winners with the new gas limit of ${newGasLimit}.`);
        console.log("This should improve the chances of successful VRF fulfillment.");
      } else {
        console.error("❌ Something went wrong. The callback gas limit was not updated correctly.");
      }
      
    } catch (error) {
      console.error("Error during callback gas limit update:", error);
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
