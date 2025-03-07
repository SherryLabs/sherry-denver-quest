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

### Raffle contract

#### Steps
1. Coordinatior contract: execute createSuscription() and get suscriptionId from logs
2. deploy raffle contract `npm testnet:deploy:raffle`
3. Coordinatior contract: execute addConsumer(subId, raffleAddress)
4, Link token contract: execute transferAndCall(coordinatorAddress, amount, abi.encode(subId)) amount: 1000000000000000000 (1 $LINK)
5. Raffle contract: execute electWinners()


### Contracts verification
```bash
npx hardhat verify --network alfajores <MOCK-POAP-ADDRESS>
npx hardhat verify --network alfajores --constructor-args poapVerifierArgs.js <POAP-VERIFIER-ADDRESS>
npx hardhat verify --network alfajores --constructor-args raffleArgs.js <RAFFLE-ADDRESS>
```

## MAINNET

### Contract deployment
```bash
npm run mainnet:deploy:poapverifier
npx hardhat verify --network celo --constructor-args poapVerifierArgs.js <POAP-VERIFIER-ADDRESS>
```

### Raffle contract ⚠️ UNDER CONSTRUCTION ⚠️

#### Steps
1. Coordinatior contract: execute createSuscription() and get suscriptionId from logs
2. deploy raffle contract `npm mainnet:deploy:raffle`
3. Coordinatior contract: execute addConsumer(subId, raffleAddress)
4, Link token contract: execute transferAndCall(coordinatorAddress, amount, abi.encode(subId)) amount: 1000000000000000000 (1 $LINK)
5. Raffle contract: execute electWinners()

### Contracts verification
```bash
npx hardhat verify --network celo --constructor-args poapVerifierArgs.js <POAP-VERIFIER-ADDRESS>
npx hardhat verify --network celo <RAFFLE-ADDRESS> <POAP-VERIFIER-ADDRESS>
```