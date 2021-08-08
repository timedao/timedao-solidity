// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20.sol";


contract simpleERC20 is ERC20UpgradeSafe {
    constructor() public ERC20UpgradeSafe() {
         ERC20UpgradeSafe.__ERC20_init("simpleERC20", "SIMPLE");
        _mint(msg.sender, 200000000000000000);        
    }
}
