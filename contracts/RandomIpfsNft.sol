// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol"; // ERC721URIStorage is an extension of ERC721 that adds a tokenURI function to set the token's URI
import "@openzeppelin/contracts/access/Ownable.sol"; // Ownable is a contract module which provides a basic access control mechanism, where there is an account (an owner) that can be granted exclusive access to specific functions.

error RandomIpfsNft__InsufficientNftMintFee();
error RandomIpfsNft__WithdrawalTransferFailed();

contract RandomIpfsNft is VRFConsumerBaseV2, ERC721URIStorage, Ownable {
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
    // map requestId to the person requesting to mint an NFT i.e. owner
    mapping(uint256 => address) private s_requestIdToSender;

    // NFT variables
    uint256 private s_tokenCounter;
    uint256 internal constant MAX_CHANCE_VALUE = 100;
    string[] internal s_dogTokenUris;
    uint256 private immutable i_mintFee;

    // Events
    event NftRequested(uint256 requestId, address requester);
    event NftMinted(Breed breed, address minter);

    // intialize chainlink vrf
    constructor(
        address vrfCoordinator,
        uint64 subscriptionId,
        bytes32 gaslane,
        uint32 callbackGasLimit,
        string[3] memory dogTokenUris,
        uint256 mintFee
    ) VRFConsumerBaseV2(vrfCoordinator) ERC721("RandomIpfsNft", "RIN") {
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        i_subscriptionId = subscriptionId;
        i_gaslane = gaslane;
        i_callbackGasLimit = callbackGasLimit;
        s_dogTokenUris = dogTokenUris;
        i_mintFee = mintFee;
    }

    // getting a random number from chainlink vrf to determine which NFT to mint
    // what is the requestId for?
    function requestNft() public payable returns (uint256 requestId) {
        if (msg.value < i_mintFee) {
            revert RandomIpfsNft__InsufficientNftMintFee();
        }

        // requestId is a unique id for each request to a chainlink vrf node
        requestId = i_vrfCoordinator.requestRandomWords(
            i_gaslane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );

        // notice how we need the requestId over here, that's why there's a small difference in the way that we return the requestId
        // see https://subscription.packtpub.com/book/application-development/9781788831383/5/ch05lvl1sec65/the-return-statement for more info
        s_requestIdToSender[requestId] = msg.sender;

        // emit event
        emit NftRequested(requestId, msg.sender);
    }

    // this function is called by a Chainlink node (msg.sender is the Chainlink node) after the random number is generated
    // the random number is provided as a uint256
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        address nftOwner = s_requestIdToSender[requestId];
        uint256 newTokenId = s_tokenCounter;

        uint256 moddedRandomNum = randomWords[0] % MAX_CHANCE_VALUE; // get a random number between 0-99
        Breed breed = getBreedFromModdedRNG(moddedRandomNum);

        s_tokenCounter += 1;
        _safeMint(nftOwner, newTokenId);

        // set token URI to the URI of the breed
        // from ERC721URIStorage
        _setTokenURI(newTokenId, s_dogTokenUris[uint256(breed)]);
        emit NftMinted(breed, nftOwner);
    }

    // use Ownable contract onlyOwner modifier
    function withdraw() public {
        uint256 amount = address(this).balance;
        (bool success, ) = payable(msg.sender).call{value: amount}("");

        if (!success) {
            revert RandomIpfsNft__WithdrawalTransferFailed();
        }
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

    // get mint fee
    function getMintFee() public view returns (uint256) {
        return i_mintFee;
    }

    // get token uri of a token
    function getDogTokenUri(uint256 index) public view returns (string memory) {
        return s_dogTokenUris[index];
    }

    // get token counter
    function getTokenCounter() public view returns (uint256) {
        return s_tokenCounter;
    }
}
