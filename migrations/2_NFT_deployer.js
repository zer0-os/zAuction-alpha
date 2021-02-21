const Fake721 = artifacts.require("Fake721");
const Fake1155 = artifacts.require("Fake1155");
const FakeZNS = artifacts.require("FakeZNS");
const FakeERC20 = artifacts.require("FakeERC20");



module.exports = function (deployer) {
  deployer.deploy(Fake721);
  deployer.deploy(Fake1155);
  deployer.deploy(FakeZNS);
  deployer.deploy(FakeERC20);
};
