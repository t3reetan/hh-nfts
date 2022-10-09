// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol"; // ERC721URIStorage is an extension of ERC721 that adds a tokenURI function to set the token's URI

contract RandomIpfsNft is VRFConsumerBaseV2, ERC721URIStorage {
    // Flow:
    // 1. call mint nft function
    // 2. calls chainlink vrf
    // 3. get random num
    // 4. use random num to get a random NFT

    // Different types of NFTs:
    // 1. Shiba: Ultra rare
    // 2. Pug: rare
    // 3. St. Bernard: common

    // Type variables
    enum Breed {
        SHIBA,
        PUG,
        ST_BERNARD
    }

    // Chainlink VRF variables
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    uint64 private immutable i_subscriptionId;
    bytes32 private immutable i_gaslane;
    uint32 private immutable i_callbackGasLimit;

    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    // Chainlink VRF helpers
    mapping(uint256 => address) private s_requestIdToSender;

    // NFT variables
    uint256 private s_tokenCounter;
    uint256 internal constant MAX_CHANCE_VALUE = 100;
    string[] internal s_tokenUris;

    // intialize chainlink vrf
    constructor(
        address vrfCoordinator,
        uint64 subscriptionId,
        bytes32 gaslane,
        uint32 callbackGasLimit,
        string[3] memory tokenUris
    ) VRFConsumerBaseV2(vrfCoordinator) ERC721("RandomIpfsNft", "RIN") {
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        i_subscriptionId = subscriptionId;
        i_gaslane = gaslane;
        i_callbackGasLimit = callbackGasLimit;
        s_tokenUris = tokenUris;
    }

    // getting a random number from chainlink vrf to determine which NFT to mint
    function requestNft(uint256 requestId) public {
        requestId = i_vrfCoordinator.requestRandomWords(
            i_gaslane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );

        s_requestIdToSender[requestId] = msg.sender;
    }

    // this function is called by a chainlink node after the random number is generated
    // the random number is provided as a uint256
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        address nftOwner = s_requestIdToSender[requestId];
        uint256 newTokenId = s_tokenCounter;

        uint256 moddedRandomNum = randomWords[0] % MAX_CHANCE_VALUE; // get a random number between 0-99
        Breed breed = getBreedFromModdedRNG(moddedRandomNum);

        _safeMint(nftOwner, newTokenId);
        _setTokenURI(newTokenId, s_tokenUris[uint256(breed)]);
    }

    function getBreedFromModdedRNG(uint256 moddedRandomNum) public pure returns (Breed) {
        if (moddedRandomNum < 10) {
            return Breed.SHIBA; // 10% chance to get a shiba
        } else if (moddedRandomNum < 30) {
            return Breed.PUG; // 20% chance to get a pug
        } else {
            return Breed.ST_BERNARD; // 70% chance to get a st. bernard
        }
    }

    // what's the use of this?
    function getChanceArray() public pure returns (uint256[3] memory) {
        return [10, 30, MAX_CHANCE_VALUE];
    }
}
