console.log("in tests");
const Web3 = require("web3");
const truffleAssert = require("truffle-assertions");
const web3 = new Web3(new Web3.providers.HttpProvider("http://localhost:8545"));
const ZAuction = artifacts.require("ZAuction");
const Fake721 = artifacts.require("Fake721");
const Fake1155 = artifacts.require("Fake1155");
const FakeZNS = artifacts.require("FakeZNS");
const FakeERC20 = artifacts.require("FakeERC20");


contract("ZAuction", (accounts) => {
  console.log("starting tests");
  const ONE_DAY = 1000 * 86400;
  const ONE_YEAR = 365 * ONE_DAY;
  let account_one = accounts[0];
  let account_two = accounts[1];
  let account_three = accounts[2];
  let account_four = accounts[3];
  let zAuction;
  let fake721;
  let fake1155;
  let fakeZNS;
  let fakeERC20;



  before(async function () {
    zAuction = await ZAuction.deployed();
    fake721 = await Fake721.deployed();
    fakeZNS = await FakeZNS.deployed();
    fake1155 = await Fake1155.deployed();
    fakeERC20 = await FakeERC20.deployed();
    await fake721.mintNewNFT("The fakest ERC721 NFT Ever!");
    await fakeZNS.mintNewNFT("The fakest ZNS NFT Ever!")
    await fake1155.mintNewNFT( 1, 0)

  });
  ///////////////////////////////////////////////////////////////////////////////////
   it("should allow account one to set a fee for their ERC721 tokens", async () => {
    await zAuction.setCreatorFees(FakeERC20.address, fake721.address, 10, 0, false)
    let setFee = await zAuction.addressNFTtoFee(fake721.address);
    console.log("the fee set for the Fake721 contract is: " + setFee);

   });
  ///////////////////////////////////////////////////////////////////////////////////
   it("should allow for the listing of a fake ERC721 token", async () => {
      let balance = await fake721.ownerOf(1);
      console.log("owner of token one: " + balance);
      await zAuction.createAuction(
        fake721.address,
        FakeERC20.address,
        1,
        web3.utils.toWei("5"),
        0,
        false,
        false,
        0
      );

      let auctionData = await zAuction.idToAuction721(1);
      console.log(auctionData)
   });
   ///////////////////////////////////////////////////////////////////////////////////
   it("should allow for the listing of a fake ERC1155 token", async () => {
      let balance = await fake1155.balanceOf(account_one, 1);
      console.log("owner of token one: " + balance);
      await zAuction.createAuction(
        fake1155.address,
        FakeERC20.address,
        1,
        web3.utils.toWei("5"),
        1,
        true,
        false,
        0
      );

      let auctionData = await zAuction.idToAuction1155(2);
      console.log(auctionData)
   });
///////////////////////////////////////////////////////////////////////////////////
   it("should allow for the listing of a fake ZNS domain", async () => {
      let balance = await fakeZNS.ownerOf(1);
      console.log("owner of token one: " + balance);
      await zAuction.createAuction(
        fakeZNS.address,
        FakeERC20.address,
        1,
        web3.utils.toWei("5"),
        0,
        false,
        true,
        0
      );

      let auctionData = await zAuction.idToAuction721(3);
      console.log(auctionData)
   });
   //////////////////////////////////////////////////////////////////////////////////
      it("should allow account two to bid on the fake ERC721", async () => {
        await fakeERC20.transfer(account_two, web3.utils.toWei("1000"))
         await zAuction.bid(
           1,
           web3.utils.toWei("6"),
           "Hello, I would REALLY like this 721 NFT pretty please",
           {from : account_two}
         );

         let auctionData = await zAuction.viewBid(1, 0);
         console.log(auctionData)
      });
      //////////////////////////////////////////////////////////////////////////////////
       it("should allow account two to bid on the fake ERC1155", async () => {

          await zAuction.bid(
            2,
            web3.utils.toWei("6"),
            "Hello, I would REALLY like this 1155 NFT pretty please",
            {from : account_two}
          );

          let auctionData = await zAuction.viewBid(2, 0);
          console.log(auctionData)
         });
  //////////////////////////////////////////////////////////////////////////////////
      it("should allow account two to bid on the fake ERC1155", async () => {

       await zAuction.bid(
           3,
           web3.utils.toWei("6"),
           "Hello, I would REALLY like this ZNS pretty please",
           {from : account_two}
         );

             let auctionData = await zAuction.viewBid(3, 0);
             console.log(auctionData)
            });
   //////////////////////////////////////////////////////////////////////////////////
    it("should allow account one to accept acount two's 721 bid", async () => {
      await fakeERC20.approve(zAuction.address,  web3.utils.toWei("600"), {from: account_two});
      await fake721.approve(zAuction.address,  1);

           await zAuction.acceptBid(
            1,
            0
           );
           let bal = await fakeERC20.balanceOf(account_one);
           console.log("The balance of account one after bid accepted: " + bal)
           let owner721 = await fake721.ownerOf(1);
           console.log("the owner of fake erc721 nft # 1 is: " + owner721)
           console.log("account one is: " + account_one)
           console.log("account two is: " + account_two)
});
//////////////////////////////////////////////////////////////////////////////////
 it("should allow account one to accept acount two's 1155 bid", async () => {
   await fake1155.setApprovalForAll(zAuction.address,  true);

        await zAuction.acceptBid(
         2,
         0
        );
        let bal = await fakeERC20.balanceOf(account_one);
        console.log("The balance of account one after bid accepted: " + bal)
        let balof2 = await fake1155.balanceOf(account_two, 1);
        console.log("the 1155 balance of account 2 after bid accepted is: " + balof2)

});
//////////////////////////////////////////////////////////////////////////////////
 it("should allow account one to accept acount two's 1155 bid", async () => {
   await fakeZNS.approve(zAuction.address,  1);
        await zAuction.acceptBid(
         3,
         0
        );
        let bal = await fakeERC20.balanceOf(account_one);
        console.log("The balance of account one after bid accepted: " + bal)
        let ownerZNS = await fakeZNS.ownerOf(1);
        console.log("the owner of fake ZNS # 1 is: " + ownerZNS)
        console.log("account one is: " + account_one)
        console.log("account two is: " + account_two)

});
});
