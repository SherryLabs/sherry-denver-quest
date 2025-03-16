const fs = require('fs');
const participants = require('../participants.json');

function generateFiles() {
    const tokenIds = participants.map(p => p.tokenId);
    const tokenIdOwnerPairs = participants.map(p => ({
        tokenId: p.tokenId,
        owner: p.owner
    }));

    fs.writeFileSync('tokenIds.json', JSON.stringify(tokenIds, null, 2));
    fs.writeFileSync('tokenIdOwnerPairs.json', JSON.stringify(tokenIdOwnerPairs, null, 2));

    console.log('Files generated successfully.');
}

generateFiles();
