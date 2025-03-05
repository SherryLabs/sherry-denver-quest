# POAPs Denver Quest


## Installation

### Install dependencies
`npm i`

### Set Up environment variables
`cp .env-example .env`

## Testnet

### Contracts deployment and POAPs minting
```bash
npm run testnet:deploy:mockpoap
npm run testnet:deploy:poapverifier
npm run testnet:mint:poaps
```

### Raffle contract ⚠️ UNDER CONSTUCTION ⚠️
> Before the Raffle contract deployment, take in account that the POAPVerifier contract must be finished. In order to put the contract at finished state you must register at least 6 users and execute the `finishRegistration()` function, after that you can deply de Raffle contract:

```bash
npm testnet:deploy:raffle
```

### Contracts verification
```bash
npx hardhat verify --network alfajores <MOCK-POAP-ADDRESS>
npx hardhat verify --network alfajores --constructor-args poapVerifierArgs.js <POAP-VERIFIER-ADDRESS>
npx hardhat verify --network alfajores <RAFFLE-ADDRESS> <POAP-VERIFIER-ADDRESS>
```

## Mainnet

### Contract deployment
```bash
npm run mainnet:deploy:poapverifier
npx hardhat verify --network celo --constructor-args poapVerifierArgs.js <POAP-VERIFIER-ADDRESS>
```
### Raffle contract ⚠️ UNDER CONSTUCTION ⚠️
> Before the Raffle contract deployment, take in account that the POAPVerifier contract must be finished. In order to put the contract at finished state you must register at least 6 users and execute the `finishRegistration()` function, after that you can deply de Raffle contract:

```bash
npm mainnet:deploy:raffle
```

### Contracts verification
```bash
npx hardhat verify --network celo --constructor-args poapVerifierArgs.js <POAP-VERIFIER-ADDRESS>
npx hardhat verify --network celo <RAFFLE-ADDRESS> <POAP-VERIFIER-ADDRESS>
```