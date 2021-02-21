pragma solidity ^0.6.6;



abstract contract IZNS {
  function creatorOf(uint256 id) public view virtual returns (address);
}
