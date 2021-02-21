const ZAuction = artifacts.require("ZAuction");
const Fake721 = artifacts.require("Fake721");
const Fake1155 = artifacts.require("Fake1155");
const FakeZNS = artifacts.require("FakeZNS");

module.exports = function (deployer) {
  deployer.deploy(ZAuction, FakeZNS.address, FakeZNS.address);
};
