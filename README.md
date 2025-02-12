# POAPs Denver Quest


## Installation

### Install dependencies
`npm i`

### Set Up environment variables
`cp .env-example .env`

## Testnet

### Contracts deployment and POAPs minting
```bash
npm run deploy:testnet:mockpoap
npm run deploy:testnet:poapverifier
npm run mint:testnet:poaps
```

### Contracts verification
```bash
npx hardhat verify --network alfajores <MOCK-POAP-ADDRESS>
npx hardhat verify --network alfajores --constructor-args poapVerifierArgs.js <POAP-VERIFIER-ADDRESS>
```

## Mainnet

### Contract deployment and verification
```bash
npm run deploy:mainnet:poapverifier
npx hardhat verify --network celo --constructor-args poapVerifierArgs.js <POAP-VERIFIER-ADDRESS>
```