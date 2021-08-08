// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";

contract PayableByERC20  is OwnableUpgradeSafe {
    using SafeERC20 for IERC20;
   

        /* EVENTS */
    event PaymentReceived(
        address indexed _from,
        address indexed _to,
        uint256 amount,
        string erc20_name
    );   
    // allowed ERC20 list
    mapping(string => address) allowed_ERC20;
    
    IERC20 public ERC20Token;
  



 

    /***********
    ERC20 FN
    **********/    
    function payWithERC20(       
        string memory erc20_name,
        uint256 fee,
        address payable _send_payment_to_addr,       
        uint msgValue      
    ) internal {
        if (allowed_ERC20[erc20_name] == address(0)) revert("This token is not allowed");        
        ERC20Token = IERC20(allowed_ERC20[erc20_name]);        
        uint allowance = ERC20Token.allowance(msg.sender, address(this));        
        if (fee > allowance) { revert("Insufficient balance"); }
     
        // Transfer the tokens to an external vault
        ERC20Token.safeTransferFrom(msg.sender, _send_payment_to_addr,msgValue );    
        emit PaymentReceived(msg.sender, _send_payment_to_addr, msgValue,erc20_name); 
    }

    function addEditERC20Token(string memory name, address erc20_address)
        public   
        onlyOwner     
        returns (address)
    {        
        allowed_ERC20[name] = erc20_address;
        return erc20_address;
    }

    function removeERC20Token(string memory name)
        public  
       onlyOwner        
        returns (bool)
    {       
        delete allowed_ERC20[name];
        return true;
    }

    function getERC20TokenAddress(string memory name)
        public
        onlyOwner
        view
        
        returns (address)
    {
        
        return allowed_ERC20[name];
    }

    function getERC20TokenBalance(string memory name)
        public
        onlyOwner
        view
        
        returns (uint256)
    {
        
        IERC20 Token;
        Token = IERC20(allowed_ERC20[name]);
        return Token.balanceOf(address(this));
    }

    function transferERC20TokenBalance(string memory name, address payable _to)
        public
        onlyOwner
        returns (uint256)
    {
        IERC20 Token;
        Token = IERC20(allowed_ERC20[name]);
        Token.safeTransfer(_to, Token.balanceOf(address(this)));
        return Token.balanceOf(address(this));
    }

}
