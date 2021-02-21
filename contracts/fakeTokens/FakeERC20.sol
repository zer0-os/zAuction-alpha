pragma solidity ^0.6.2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract FakeERC20 is Ownable, ERC20 {
    constructor() public ERC20("FakeERC20", "FER") {
        _Mint(msg.sender, 1000000000000000000000000000);

    }

    function _Mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
    }

    function _Burn(address _from, uint256 _amount) public onlyOwner {
        _burn(_from, _amount);
    }
}
