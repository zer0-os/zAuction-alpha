pragma solidity ^0.6.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155Holder.sol";
import "./interfaces/IZNS.sol";

contract ZAuction is ERC721Holder, ERC1155Holder {
  using SafeMath for uint;
    uint256 public auctionID;
    IZNS public znsRegistryContract;
    address public zns721;

    mapping(uint256 => bool) public openAuction;
    mapping(uint256 => bool) public auctionIDtoType;
    mapping(uint256 => Auction721) public idToAuction721;
    mapping(uint256 => Auction1155) public idToAuction1155;
    mapping(address => uint256) public addressNFTtoFee;
    mapping(uint256 => uint256) public znsIDtoFee;
    mapping(address => IERC20) public addressNFTtoAddressFeeERC20;
    mapping(uint256 => IERC20) public znsIDtoAddressFeeERC20;
    mapping(address => address) public addressNFTtoCreator;
    mapping(uint256 => address) public znsIDtoCreator;

    struct Auction721 {
        IERC721 nftContract;
        IERC20 bidERC20Contract;
        address seller;
        address highestBidder;
        uint256 highestBid;
        uint256 nftId;
        uint256 startPrice;
        uint256 bidID;
        bool isZNS;
        mapping(uint256 => BidInfo) bids;
    }

    struct Auction1155 {
        IERC1155 nftContract;
        IERC20 bidERC20Contract;
        address seller;
        address highestBidder;
        uint256 highestBid;
        uint256 nftId;
        uint256 startPrice;
        uint256 bidID;
        uint256 amount;
        bytes callData;
        mapping(uint256 => BidInfo) bids;
    }

    struct BidInfo {
        address bidder;
        uint256 bidAmount;
        bool bidApproved;
        string IPFShash;
    }

    constructor(IZNS _znsRegAdd, address _ZND721) public {
        znsRegistryContract = _znsRegAdd;
        zns721 = _ZND721;
    }

    /**
@notice createAuction allows a NFT owner to create an auction for both a 721 and 1155 NFT
@param _NFTcontract is the address of the NFT contract whos token is being auctioned
@param _bidERC20 is the address of the ERC20 contract this auction will be held in
@param _tokenId is the ID of the NFT token(s) being auctioned
@param _startPrice is the starting price of the auction priced in the bid ERC20 token
@param _amount is an amount of NFTs to be transfered(1155 only, set to 0 if ERC721)
@param _is1155 is a bool representing whether or not the NFT being auctioned is ERC1155
@param _callData is the relevant call data for the NFT if it is ERC1155(leave blank if ERC721)
**/
    function createAuction(
        address _NFTcontract,
        IERC20 _bidERC20,
        uint256 _tokenId,
        uint256 _startPrice,
        uint256 _amount,
        bool _is1155,
        bool _isZNS,
        bytes memory _callData
    ) public {
        auctionID++;
        if (_is1155) {
            IERC1155 nft = IERC1155(_NFTcontract);
            if(address(addressNFTtoAddressFeeERC20[_NFTcontract]) != address(0)){
              require(addressNFTtoAddressFeeERC20[_NFTcontract] == _bidERC20);
            }
            require(nft.balanceOf(msg.sender, _tokenId) >= 1);
            Auction1155 memory auction = idToAuction1155[auctionID];
            auction.nftContract = nft;
            auction.seller = msg.sender;
            auction.bidERC20Contract = _bidERC20;
            auction.startPrice = _startPrice;
            auction.nftId = _tokenId;
            auction.amount = _amount;
            auction.callData = _callData;

            idToAuction1155[auctionID] = auction;
            openAuction[auctionID] = true;
            auctionIDtoType[auctionID] = true;
        } else {
            IERC721 nft = IERC721(_NFTcontract);
            require(msg.sender == nft.ownerOf(_tokenId));
            if(address(addressNFTtoAddressFeeERC20[_NFTcontract]) != address(0)){
              require(addressNFTtoAddressFeeERC20[_NFTcontract] == _bidERC20);
            }
            Auction721 memory auction = idToAuction721[auctionID];
            auction.nftContract = nft;
            auction.seller = msg.sender;
            auction.bidERC20Contract = _bidERC20;
            auction.startPrice = _startPrice;
            auction.nftId = _tokenId;
            auction.isZNS = _isZNS;

            idToAuction721[auctionID] = auction;
            openAuction[auctionID] = true;
            auctionIDtoType[auctionID] = false;
        }
    }

    /**
@notice bid allows any user to bid on an auction
@param _auctionID is the number representing the ID of the auction being bid on
@param _bidAmount is the ERC20 amount being placed as a bid for the auction
@param _IPFShash is an optional IPFS hash that allows a bidder to relay a message to the NFT owner
**/
    function bid(
        uint256 _auctionID,
        uint256 _bidAmount,
        string memory _IPFShash
    ) public {
        require(openAuction[_auctionID], "ERROR: Auction has ended");
        if (auctionIDtoType[_auctionID]) {
            Auction1155 storage auction = idToAuction1155[_auctionID];
            auction.bidID = auction.bidID++;

            BidInfo memory currentBid =
                BidInfo({
                    bidder: msg.sender,
                    bidAmount: _bidAmount,
                    bidApproved: false,
                    IPFShash: _IPFShash
                });

            auction.bids[auction.bidID] = currentBid;

            if (_bidAmount >= auction.highestBid) {
                auction.highestBidder = msg.sender;
                auction.highestBid = _bidAmount;
            }
        } else {
            Auction721 storage auction = idToAuction721[_auctionID];
            auction.bidID = auction.bidID++;
            BidInfo memory currentBid =
                BidInfo({
                    bidder: msg.sender,
                    bidAmount: _bidAmount,
                    bidApproved: false,
                    IPFShash: _IPFShash
                });

            auction.bids[auction.bidID] = currentBid;
            if (_bidAmount >= auction.highestBid) {
                auction.highestBidder = msg.sender;
                auction.highestBid = _bidAmount;
            }
        }
    }

    /**
@notice acceptBid allows an NFT owner/auctioner to accept a placed bid
@param _auctionID is the number representing the Auction where the bid is placed
@param _bidID is the number representing the bid being accepted
@dev this function allows an NFT owner to accept ANY placed bid regardless of if it is the highest bid or not
**/
    function acceptBid(uint256 _auctionID, uint256 _bidID) public {
        require(openAuction[_auctionID], "ERROR: Auction has ended");

        if (auctionIDtoType[_auctionID]) {
            Auction1155 storage auction = idToAuction1155[_auctionID];
            BidInfo memory currentBid = auction.bids[_bidID];
            require(
                auction.seller == msg.sender,
                "ERROR: You are not the owner of this NFT Auction"
            );
            require(
                auction.bidERC20Contract.balanceOf(currentBid.bidder) >=
                    currentBid.bidAmount,
                "Bidders balance too low"
            );
            uint fee;
            if(addressNFTtoFee[address(auction.nftContract)] != 0) {
              fee = _percent(
                currentBid.bidAmount,
                addressNFTtoFee[address(auction.nftContract)],
                2
              );
            }
            uint remainder = currentBid.bidAmount.sub(fee);

            auction.bidERC20Contract.transferFrom(
                currentBid.bidder,
                auction.seller,
                remainder
            );
              if(addressNFTtoCreator[address(auction.nftContract)] != address(0)) {
            auction.bidERC20Contract.transferFrom(
                currentBid.bidder,
                addressNFTtoCreator[address(auction.nftContract)],
                fee
            );
          }
            auction.nftContract.safeTransferFrom(
                auction.seller,
                currentBid.bidder,
                auction.nftId,
                auction.amount,
                auction.callData
            );
        } else {
            Auction721 storage auction = idToAuction721[_auctionID];
            BidInfo memory currentBid = auction.bids[_bidID];
            require(
                auction.seller == msg.sender,
                "ERROR: You are not the owner of this NFT Auction"
            );
            require(
                auction.bidERC20Contract.balanceOf(currentBid.bidder) >=
                    currentBid.bidAmount,
                "Bidders balance too low"
            );
            uint fee;

            if(addressNFTtoFee[address(auction.nftContract)] != 0
          || znsIDtoFee[auction.nftId] != 0) {
            if(!auction.isZNS){
               fee =
               _percent(
                currentBid.bidAmount,
                addressNFTtoFee[address(auction.nftContract)],
                1
              );
            } else {
               fee = _percent(
                currentBid.bidAmount,
                znsIDtoFee[auction.nftId],
                1
              );

            }
          }
            uint remainder = currentBid.bidAmount.sub(fee);

            auction.bidERC20Contract.transferFrom(
                currentBid.bidder,
                auction.seller,
                remainder
            );
            if(addressNFTtoCreator[address(auction.nftContract)] != address(0)) {
              auction.bidERC20Contract.transferFrom(
                currentBid.bidder,
                addressNFTtoCreator[address(auction.nftContract)],
                fee
              );
            }
            auction.nftContract.safeTransferFrom(
                auction.seller,
                currentBid.bidder,
                auction.nftId
            );
        }
        openAuction[_auctionID] = false;

    }

    /**
@notice cancel allows an NFT owner/ auction creator to cancle their auction
@param _auctionID is the number representing the auction that is being cancled
**/
    function cancel(uint256 _auctionID) public {
        require(openAuction[_auctionID], "ERROR: Auction has ended");
        if (auctionIDtoType[_auctionID]) {
            Auction1155 memory auction = idToAuction1155[_auctionID];
            require(auction.seller == msg.sender);
            delete idToAuction1155[_auctionID];
        } else {
            Auction721 memory auction = idToAuction721[_auctionID];
            require(auction.seller == msg.sender);
            delete idToAuction1155[_auctionID];
        }
        openAuction[_auctionID] = false;
    }

    /**
@notice cancelBid allows a bidder to cancel their bid
@param _auctionID is the number representing the auction that is being cancled
@param _bidID is the number representing the users bid
**/
    function cancelBid(uint256 _auctionID, uint256 _bidID) public {
        require(openAuction[_auctionID], "ERROR: Auction has ended");
        if (auctionIDtoType[_auctionID]) {
            Auction1155 storage auction = idToAuction1155[_auctionID];
            require(auction.bids[_bidID].bidder == msg.sender);
            delete auction.bids[_bidID];
        } else {
            Auction721 storage auction = idToAuction721[_auctionID];
            require(auction.bids[_bidID].bidder == msg.sender);
            delete auction.bids[_bidID];
        }
    }

    /**
@notice setCreatorFees allows the owner of an NFT contract OR the owner of a ZNS domain to
        set a creator fee for all sales of their NFTs through the platform
@param _ERC20FeeAdd is the address of the ERC20 contract NFT will be purchased in
@param _NFTContractAdd is the address of the NFT contract they own
@param _feePercentage is the percentage of a sale that will be collected in fee's
@param _znsID is the ZNS ID for a ZNS domain
@param _isZNS is a bool representing whether or not the NFT set is a ZNS domain
**/
    function setCreatorFees(
        IERC20 _ERC20FeeAdd,
        address _NFTContractAdd,
        uint256 _feePercentage,
        uint256 _znsID,
        bool _isZNS
    ) public {
        if (_isZNS) {
          require(msg.sender == znsRegistryContract.creatorOf(_znsID));
          znsIDtoFee[_znsID] = _feePercentage;
          znsIDtoAddressFeeERC20[_znsID] = _ERC20FeeAdd;
          znsIDtoCreator[_znsID] = msg.sender;
        } else {
          Ownable nft = Ownable(_NFTContractAdd);
          require(msg.sender == nft.owner());
          addressNFTtoFee[_NFTContractAdd] = _feePercentage;
          addressNFTtoAddressFeeERC20[_NFTContractAdd] = _ERC20FeeAdd;
          addressNFTtoCreator[_NFTContractAdd] = msg.sender;
        }
    }

/**
@notice viewBid allows for the front end to easily retreive a specific bids info
@param _auctionID is the number representing the auction that is being cancled
@param _bidID is the number representing the users bid
**/
    function viewBid(uint _auctionID, uint _bidID) public view returns(BidInfo memory) {
      if(auctionIDtoType[_auctionID]){
        Auction1155 storage auction = idToAuction1155[_auctionID];
        return auction.bids[_bidID];
    } else {
        Auction721 storage auction = idToAuction721[_auctionID];
        return auction.bids[_bidID];
      }
    }

    /**
    @notice percent is an internal function used to calculate the ratio between a given numerator && denominator
    @param _numerator is the numerator of the equation
    @param _denominator is the denominator of the equation
    @param _precision is a precision point to ensure that decimals dont trail outside what the EVM can handle
    **/
    function _percent(
        uint256 _numerator,
        uint256 _denominator,
        uint256 _precision
    ) public pure returns (uint256 quotient) {
        // caution, check safe-to-multiply here
        uint256 numerator = _numerator * 10**(_precision + 1);
        // with rounding of last digit
        uint256 _quotient = ((numerator / _denominator) + 5) / 10;
        return (_quotient);
    }
}
