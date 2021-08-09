# TimeAtom smart  contract

## A word of caution
This SDK and corresponding smart contracts are currently in alpha, use at your own risks

TimeAtom is a decentralized key-value store with a built-in timelock feature.
It is meant to store timelocked tuples.

A tuple is composed of :
- a hashedKey : the key that will identify the tuple
- a permanent field : accessible at all time with the hashedKey
- a timelocked field : accessible only after the opening date
- a timestamp representing the desired opening date

### Public Methods
-  **checkHashKey**(string memory hashKey) public view returns (bool)
  <br>*Method used to check if a specific hashkey already exists* 
-  **calculateFee**(uint256 endDate) public view returns (uint256) 
 <br>*Returns the cost to store a tuple until "endDate".* 
-  **makeAtom**(string memory hashKey,string memory _public_content,string memory _timelocked_content,int256 opening_date) public payable
  <br>*Method used to store a tuple, payment must be sent in the native token of the network : ETH for Ethereum networks, xDAI for the xdai network* 

-  **makeAtomERC20**(string memory erc20_name,string memory name,string memory _public_content,string memory _timelocked_content,uint256 opening_date,uint msgValue) public
  <br>*Method used to store a tuple, payment must be sent in the declaraed ERC20 token (needs PayableByERC20 to be configured beforehand to accept this specific token)* 

-  **getAtom**(string memory hashKey) public view returns (bytes memory)
  <br>*Method used to retrieve a tuple. If tuple is still timelocked the call will return the opening date* 

-  **getPublicContent**(string memory hashKey) public view returns (bytes memory)
 <br>*Method used to retrieve a tuple's public content* 


## Contract deployment address on xdai
0x6D5050dc441845bADA25a46BBC5f9783794E4085

## Testing the code
npm install truffle -g (if not already installed) <br>
Install the modules : npm install<br>
Setup your test environment : fire ganache, configure truffle-init.js,etc...<br>
Tweak migrations : add/remove the deployment of simpleERC20 contract, it is here only for testing purposes
<br>
Compile and deploy the contracts : truffle compile --all, then truffle migrate --reset<br>
<br>
Unit tests : truffle test