import { Request, Response } from 'express';
import { Metadata, BlockchainActionMetadata, Abi, createMetadata, ValidatedMetadata, Chain } from "@sherrylinks/sdk"

export function miniApp(req: Request, res: Response) {
    try {
        const abi: Abi = [
            {
                "inputs": [
                    {
                        "internalType": "address",
                        "name": "_user",
                        "type": "address"
                    }
                ],
                "name": "checkAndRegister",
                "outputs": [],
                "stateMutability": "nonpayable",
                "type": "function"
            }
        ] as const

        const action: BlockchainActionMetadata = {
            label: "Register",
            address: `0x${process.env.CONTRACT_ADDRESS}`,
            abi,
            functionName: "checkAndRegister",
            chain: process.env.NETWORK as Chain
        }

        const metadata: Metadata = {
            type: "action",
            url: "https://sherry.social/links",
            icon: "icon",
            title: "Denver POAPs Quest",
            description: "Mini App For Denver POAPs Quest.",
            actions: [action]
        };

        const metadataResponse: ValidatedMetadata = createMetadata(metadata);
        res.status(200).json(metadataResponse);
    } catch (error) {
        res.status(500).json(error);
    }
}