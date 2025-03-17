const hre = require("hardhat");

async function main() {
  try {
    console.log("Checking raffle winners...");
    
    // Get the deployed contract address
    const raffleAddress = '0x2e3b71cF183657582F03c44F35fECF235677C1ED';
    console.log(`Connecting to Raffle contract at: ${raffleAddress}`);
    
    // Get the contract factory and attach to the deployed contract
    const Raffle = await hre.ethers.getContractFactory("Raffle");
    const raffle = Raffle.attach(raffleAddress);
    
    // Check if raffle has ended
    const raffleEnded = await raffle.raffleEnded();
    console.log(`Raffle ended: ${raffleEnded}`);
    
    if (!raffleEnded) {
      console.log("The raffle hasn't ended yet. Winners are not selected.");
      console.log("The Chainlink VRF might still be processing your request.");
      
      // Get requestId to check on the Chainlink VRF explorer
      const requestId = await raffle.s_requestId();
      if (requestId && !requestId.eq(0)) {
        console.log(`Pending request ID: ${requestId.toString()}`);
        console.log(`You can check the status of your request on the Chainlink VRF explorer.`);
      } else {
        console.log("No request has been made yet or request ID is not available.");
      }
      return;
    }
    
    // Get winners
    const winners = await raffle.getWinners();
    console.log("🎉 Winners have been selected! 🎉");
    console.log("----------------------------------------");
    
    for (let i = 0; i < winners.length; i++) {
      console.log(`Winner ${i+1}: ${winners[i]}`);
    }
    console.log("----------------------------------------");
    
    // Verify if winners are actually in the verified users list
    console.log("\nVerifying winners...");
    for (let i = 0; i < winners.length; i++) {
      const isVerified = await raffle.isUserVerified(winners[i]);
      console.log(`Winner ${i+1} (${winners[i]}) verified: ${isVerified}`);
    }
    
  } catch (error) {
    console.error("Error checking winners:", error);
  }
}

// Execute the script
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
