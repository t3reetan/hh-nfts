// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

pragma solidity ^0.8.9;

contract BasicNFT is ERC721 {
    // 1. check ERC-721 standard to see what functions you need
    // 2. use openzeppelin contracts

    string public constant TOKEN_URI =
        "ipfs://bafybeig37ioir76s7mg5oobetncojcm3c3hxasyd4rvid4jqhy4gkaheg4/?filename=0-PUG.json";
    uint256 private s_tokenCounter;

    constructor() ERC721("Dogy", "DOG") {
        s_tokenCounter = 0;
    }

    function mintNft() public returns (uint256) {
        _safeMint(msg.sender, s_tokenCounter);
        s_tokenCounter++;

        return s_tokenCounter;
    }

    function tokenURI(
        uint256 /* tokenId */
    ) public view override returns (string memory) {
        return TOKEN_URI;
    }

    function getTokenCounter() public view returns (uint256) {
        return s_tokenCounter;
    }

    // tokenURI function is going to tell us exactly how our NFT will look like
}
