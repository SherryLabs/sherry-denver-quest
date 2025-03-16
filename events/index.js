const { ethers } = require("ethers");
const fs = require("fs");

const FROM_BLOCK = parseInt(30580000, 10);
const PARTICIPANTS_FILE = "participants.json";
const TOKEN_IDS_FILE = "tokenIds.json";
const TARGET_EVENT_ID = "185509";

const contractAbi = [
  "event Mint(uint256 indexed eventId, uint256 indexed poapId, address indexed owner)",
];
const provider = new ethers.JsonRpcProvider("https://forno.celo.org");
const contract = new ethers.Contract(
  "0x22C1f6050E56d2876009903609a2cC3fEf83B415",
  contractAbi,
  provider
);

async function fetchAndStoreEvents() {
  try {
    const latestBlock = await provider.getBlockNumber();
    console.log(`\nLatest block: ${latestBlock}`);

    console.log(
      `Getting logs from block nuember ${FROM_BLOCK} to ${latestBlock}...`
    );
    const events = await contract.queryFilter("Mint", FROM_BLOCK, latestBlock);

    const participants = events
      .map((e) => ({
        eventId: e.args.eventId.toString(),
        tokenId: e.args.poapId.toString(),
        owner: e.args.owner.toLowerCase(),
        transactionHash: e.transactionHash,
      }))
      .filter((e) => e.eventId === TARGET_EVENT_ID);

    if (participants.length > 0) {
      console.log(
        `Found ${participants.length} addresses with poap with eventId = ${TARGET_EVENT_ID}`
      );

      const tokenIds = participants.map((p) => p.tokenId);

      fs.writeFileSync(
        PARTICIPANTS_FILE,
        JSON.stringify(participants, null, 2)
      );
      console.log(`Participants stored in: ${PARTICIPANTS_FILE}`);
      fs.writeFileSync(TOKEN_IDS_FILE, JSON.stringify(tokenIds, null, 2));
      console.log(`TokenIds stored in: ${TOKEN_IDS_FILE}`);
    } else {
      console.log(`There is no poaps with eventId = ${TARGET_EVENT_ID}`);
    }
  } catch (error) {
    console.error("Error al obtener eventos:", error);
  }
}

fetchAndStoreEvents();
