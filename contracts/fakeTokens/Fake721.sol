pragma solidity ^0.6.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract Fake721 is Ownable,  ERC721{
    uint256 public idTracker;


    /**
    @notice the constructor function is fired only once during contract deployment
    @dev assuming all NFT URI metadata is based on a URL he baseURI would be something like https://
    **/
    constructor() public ERC721("Fake ERC721", "F721") {
        idTracker = 0;
    }

    /**
    @notice mintNewNFT allows the owner of this contract to mint an input address a newNFT
    @param _tokenURI is the input metadata for the token being created
    **/
    function mintNewNFT(
        string memory _tokenURI
    ) public onlyOwner {
      idTracker++;
        _safeMint(msg.sender, idTracker);
        _setTokenURI(idTracker, _tokenURI);
    }

}
