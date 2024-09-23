// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./interface/ERC1155.sol";

contract NFT is ERC1155{
    address public owner;

    constructor()
        ERC1155("https://crimson-odd-puffin-346.mypinata.cloud/ipfs/QmNNJeC5dDBu3UrRKYwpZWF6Xe4xUE165MmPHxhD6D79PD")
    {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data)
        public
        onlyOwner
    {
        _mint(account, id, amount, data);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        public
        onlyOwner
    {
        _mintBatch(to, ids, amounts, data);
    }
}
