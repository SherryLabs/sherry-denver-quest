# POAPs Denver Quest


`cp .env-example .env`

## Testnet
```bash
npm run deploy:testnet:mockpoap
npm run deploy:testnet:poapverifier
npm run mint:testnet:poaps
```

```bash
npx hardhat verify --network alfajores <MOCK-POAP-ADDRESS>
npx hardhat verify --network alfajores --constructor-args poapVerifierArgs.js <POAP-VERIFIER-ADDRESS>
```

## Mainnet
```bash
npm run deploy:mainnet:poapverifier
npx hardhat verify --network celo --constructor-args poapVerifierArgs.js <POAP-VERIFIER-ADDRESS>
```