# POAPs Denver Quest


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
5, Link token contract: execute transferAndCall(coordinatorAddress, amount, abi.encode(subId)) amount: 1000000000000000000 (1 $LINK)
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
5, Link token contract: execute transferAndCall(coordinatorAddress, amount, abi.encode(subId)) amount: 1000000000000000000 (1 $LINK) https://snowtrace.io/address/0x5947BB275c521040051D82396192181b413227A3/contract/43114/writeContract?chainid=43114
6. Raffle contract: execute electWinners()

#### Contract verification
```bash
npx hardhat verify --network avalanche --constructor-args raffleArgs.js <RAFFLE-ADDRESS>
```