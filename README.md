# POAPs Denver Quest

A cross-chain solution for POAP verification and prize distribution using Celo and Avalanche networks.

## Contract Addresses

| Contract | Network | Address |
|----------|---------|---------|
| POAPVerifier | Celo Mainnet | [0x3449afc2fCF3D51DC892658f0c69E47286B078d4](https://celoscan.io/address/0x3449afc2fcf3d51dc892658f0c69e47286b078d4/advanced#readContract) |
| Raffle | Avalanche C-Chain |  [0x2e3b71cF183657582F03c44F35fECF235677C1ED](https://snowtrace.io/address/0x2e3b71cF183657582F03c44F35fECF235677C1ED)|

## Project Overview

This project implements a cross-chain solution for verifying POAP ownership and conducting a raffle:

1. **POAP Registration**: Users mint POAPs on the Celo network, generating unique tokenIds for each participant
2. **Verification Process**: The POAPVerifier contract validates POAP ownership
3. **Cross-Chain Raffle**: Validated participants enter a Chainlink VRF-powered raffle on Avalanche

## Setup Guide

### Installation

```bash
# Install dependencies
npm i

# Set up environment variables
cp .env-example .env
# Edit the .env file with your private keys and API endpoints
```

### Development Workflow

#### Testnet Deployment

##### POAP System
```bash
# Deploy Mock POAP contract
npm run testnet:deploy:mockpoap

# Deploy POAP Verifier contract
npm run testnet:deploy:poapverifier

# Mint test POAPs
npm run testnet:mint:poaps
```

##### Raffle Setup on Testnet
1. Using the Coordinator contract, execute `createSuscription()` and get subscriptionId from logs
2. Set environment variables for the Raffle contract in your `.env` file
3. Deploy raffle contract: `npm run testnet:deploy:raffle`
4. In Coordinator contract, execute `addConsumer(subId, raffleAddress)`
5. Fund the subscription with LINK tokens: execute `transferAndCall(coordinatorAddress, 1000000000000000000, abi.encode(subId))` from the LINK token contract
6. On the Raffle contract, execute `electWinners()` to randomly select winners

##### Contract Verification
```bash
# Verify Mock POAP contract
npx hardhat verify --network alfajores <MOCK-POAP-ADDRESS>

# Verify POAP Verifier contract
npx hardhat verify --network alfajores --constructor-args poapVerifierArgs.js <POAP-VERIFIER-ADDRESS>

# Verify Raffle contract
npx hardhat verify --network fuji --constructor-args raffleArgs.js <RAFFLE-ADDRESS>
```

#### Mainnet Deployment

##### POAPVerifier Deployment
```bash
# Deploy POAP Verifier contract to Celo mainnet
npm run mainnet:deploy:poapverifier

# Verify the contract
npx hardhat verify --network celo --constructor-args poapVerifierArgs.js <POAP-VERIFIER-ADDRESS>
```

##### Raffle Setup on Mainnet (Avalanche)
1. On Chainlink Coordinator contract: execute `createSuscription()` and get subscriptionId from logs
   - [Coordinator Contract](https://snowtrace.io/address/0xd5D517aBE5cF79B7e95eC98dB0f0277788aFF634/contract/43114/writeContract?chainid=43114)
2. Set environment variables for the Raffle contract
3. Deploy raffle contract: `npm run mainnet:deploy:raffle`
4. In Coordinator contract, execute `addConsumer(subId, raffleAddress)`
5. Fund the subscription with LINK tokens: execute `transferAndCall(coordinatorAddress, 1000000000000000000, abi.encode(subId))` from the LINK token contract
   - [LINK Token Contract](https://snowtrace.io/address/0x5947BB275c521040051D82396192181b413227A3/contract/43114/writeContract?chainid=43114)
6. On the Raffle contract, execute `electWinners()` to randomly select winners

```bash
# Verify Raffle contract
npx hardhat verify --network avalanche --constructor-args raffleArgs.js <RAFFLE-ADDRESS>
```

## Project Workflow

### 1. POAP Registration and Collection

As users participated in the Denver Quest, they minted POAPs on the Celo network. Each minted POAP generated a unique tokenId associated with the participant's address.

### 2. Generating Participant List from POAP Events

After the POAP minting period, we extracted the events to create a list of all participants:

```bash
# Script to fetch events and compile list of participants
node events/index.js

# Generate token IDs and tokenId-owner pairs
node events/getIdsFromParticipants.js
```

This process generated:
- `tokenIds.json`: An array of all valid token IDs
- `tokenIdOwnerPairs.json`: An array of objects matching each tokenId to its owner

### 3. Verification and Registration Closure

The registration period ended on March 16th. We finalized the process by:
1. Submitting all tokenIds to the POAPVerifier contract for validation
2. The verification transaction can be viewed here: [Verification Transaction](https://celoscan.io/tx/0x2ed6d3de5e24a178bb53398998e1a6aebad4c6c815fa18eca14003ebc91638d9)
3. All registered users can be verified in this transaction: [Registered Users](https://celoscan.io/tx/0x43a0ec9ab4599dcd57df09a772a1dc8888689b03b0abdde501768633436eede1)

### 4. Cross-Chain Raffle

The final list of verified participants was then:
1. Extracted from the POAPVerifier contract on Celo
2. Imported into the Raffle contract on Avalanche C-Chain
3. The Raffle contract used Chainlink VRF 2.5 to randomly and fairly select winners

The winner selection process was completed with the following transactions:
- Initial `electWinners()` execution: [Transaction Hash](https://snowtrace.io/tx/0x852dc6ad43479ff6de37dfaa95b9b38b8e37dd7fcea0e103c25d29968ba88260?chainid=43114)
- Chainlink VRF fulfillment (internal transaction): [VRF Transaction Hash](https://snowtrace.io/tx/0x2ad32d13698e0b08c20cd6e02be8a6aba9de99e29cc4334b19a8d268407a1931?chainid=43114)

## Technical Architecture

- **POAPVerifier (Celo)**: Validates POAP ownership and maintains the official list of participants
- **Raffle Contract (Avalanche)**: Manages the selection of winners using Chainlink VRF for verifiable randomness
- **Cross-Chain Integration**: Manual transfer of verified participant list from Celo to Avalanche

## Additional Resources

For technical questions or contributions, please open an issue in this repository.