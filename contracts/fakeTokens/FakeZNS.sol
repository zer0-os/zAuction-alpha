pragma solidity ^0.6.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract FakeZNS is Ownable,  ERC721{
    uint256 public idTracker;
    address public creator;


    /**
    @notice the constructor function is fired only once during contract deployment
    @dev assuming all NFT URI metadata is based on a URL he baseURI would be something like https://
    **/
    constructor() public ERC721("Fake ZNS", "ZNS") {
        idTracker = 0;
        creator = msg.sender;
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

    function creatorOf(uint256 id) public view virtual returns (address){
      return creator;
    }


}
