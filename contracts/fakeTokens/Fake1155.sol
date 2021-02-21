pragma solidity ^0.6.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract Fake1155 is Ownable,  ERC1155{
    uint256 public idTracker;


    /**
    @notice the constructor function is fired only once during contract deployment
    @dev assuming all NFT URI metadata is based on a URL he baseURI would be something like https://
    **/
    constructor() public ERC1155("Fake base URI") {
        idTracker = 0;
    }


    function mintNewNFT(
      uint256 amount,
      bytes memory data
    ) public onlyOwner {
      idTracker++;
        _mint(
          msg.sender,
          idTracker,
          amount,
          data
        );
    }


    function mintNewNFTBatch(
      uint256[] memory ids,
      uint256[] memory amounts,
      bytes memory data
    ) public onlyOwner {
      idTracker++;
        _mintBatch(
          msg.sender,
          ids,
          amounts,
          data
        );
    }

}
