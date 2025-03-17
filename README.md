# POAPs Denver Quest

## Contract Addresses

| Contract | Network | Address |
|----------|---------|---------|
| POAPVerifier | Celo Mainnet | [0x3449afc2fCF3D51DC892658f0c69E47286B078d4](https://celoscan.io/address/0x3449afc2fcf3d51dc892658f0c69e47286b078d4/advanced#readContract) |
| Raffle | Avalanche C-Chain |  |

## Installation

### Install dependencies
`npm i`

### Set Up environment variables
`cp .env-example .env`

## Testnet

### POAP contracts deployment and POAPs minting
```bash
npm run testnet:deploy:mockpoap
npm run testnet:deploy:poapverifier
npm run testnet:mint:poaps
```

### Raffle contract

#### Steps
1. Coordinatior contract: execute createSuscription() and get subscriptionId from logs
2. Set env variables for Raffle contract
3. Deploy raffle contract `npm testnet:deploy:raffle`
4. Coordinatior contract: execute addConsumer(subId, raffleAddress)
5. Link token contract: execute transferAndCall(coordinatorAddress, amount, abi.encode(subId)) amount: 1000000000000000000 (1 $LINK)
6. Raffle contract: execute electWinners()

### Contracts verification
```bash
npx hardhat verify --network alfajores <MOCK-POAP-ADDRESS>
npx hardhat verify --network alfajores --constructor-args poapVerifierArgs.js <POAP-VERIFIER-ADDRESS>
npx hardhat verify --network fuji --constructor-args raffleArgs.js <RAFFLE-ADDRESS>
```

## MAINNET

### POAPVerifier contract deployment and verification
```bash
npm run mainnet:deploy:poapverifier
npx hardhat verify --network celo --constructor-args poapVerifierArgs.js <POAP-VERIFIER-ADDRESS>
```

### Raffle contract

#### Steps to create subscription and deploy the contract
1. Coordinatior contract: execute createSuscription() and get subscriptionId from logs https://snowtrace.io/address/0xd5D517aBE5cF79B7e95eC98dB0f0277788aFF634/contract/43114/writeContract?chainid=43114
2. Set env variables for Raffle contract
3. Deploy raffle contract `npm testnet:deploy:raffle`
4. Coordinatior contract: execute addConsumer(subId, raffleAddress)
5. Link token contract: execute transferAndCall(coordinatorAddress, amount, abi.encode(subId)) amount: 1000000000000000000 (1 $LINK) https://snowtrace.io/address/0x5947BB275c521040051D82396192181b413227A3/contract/43114/writeContract?chainid=43114
6. Raffle contract: execute electWinners()

#### Contract verification
```bash
npx hardhat verify --network avalanche --constructor-args raffleArgs.js <RAFFLE-ADDRESS>
```

## Obtaining Token IDs and Participants List

### Steps to generate token IDs and participants list

1. Fetch events and store participants:
   ```bash
   node events/index.js
   ```

2. Generate token IDs and tokenId-owner pairs:
   ```bash
   node events/getIdsFromParticipants.js
   ```
3. The generated files will be:
   - `tokenIds.json`: Contains an array of all token IDs.
   - `tokenIdOwnerPairs.json`: Contains an array of objects with `tokenId` and `owner`.

4. Use the generated `tokenIds.json` to validate users in the POAPVerifier contract.

## Finish Registration

The registration was finished Sun 16 Mar, here is the [transaction hash](https://celoscan.io/tx/0x2ed6d3de5e24a178bb53398998e1a6aebad4c6c815fa18eca14003ebc91638d9), there you can validate all the `tokenId` that were sent.

## Check Registered Users

To verify the registered users sent, check the following [transaction hash](https://celoscan.io/tx/0x43a0ec9ab4599dcd57df09a772a1dc8888689b03b0abdde501768633436eede1) for the process.