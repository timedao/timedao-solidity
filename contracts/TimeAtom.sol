// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
import "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";
import './PayableByERC20.sol';

/************
TimeAtom is a decentralized keystore with timelocking feature. 
It allows users to store and timelock data onchain. 
Entries are composed of an opening date, a timelocked content (available after date) and a public content that is not timelocked and can be consulted at any time 
******************* */
   /*
 inherits :
    transferOwnership from the owner account to a new one, and
    renounceOwnership for the owner to relinquish this administrative privilege.
    */



contract TimeAtom is OwnableUpgradeSafe, PayableByERC20 {   
    /* atoms mapping : hashKey => var */
    mapping(string => bool) atoms;    
    mapping(string => string) timelocked_contents;
    mapping(string => string) public_contents;    
    mapping(string => uint256) atom_opening_date;
    bytes[] atomList;
    uint256 price_day;
    uint256 entry_fee;   

    /* EVENTS */
    event AtomReady(address indexed _from, uint256 amount, bool _value);
    event PaymentReceived(
        address indexed _from,
        address indexed _to,
        uint256 amount
    );
    event BalanceTransferedToVault(
        address indexed _from,
        address indexed _to,
        uint256 amount
    );  
    address payable private _vault_addr;
    uint256 free_period;
 
    // list of open atoms
    mapping(string => bool) open_atoms;

/*************
  INIT
*************/

    function initialize() public initializer {
        OwnableUpgradeSafe.__Ownable_init();
        _vault_addr = 0x02E32DF164bAC1cA34D7f0FC95ad665e2A41D3cf;
        entry_fee = 5;
        price_day = 5;
        free_period = 1;
    }

    function getVersion() public pure returns (string memory) {
        return "1.1.0";
    }

/*************
  ADMIN FN
*************/
    function transferBalanceToVault() public onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, bytes memory data) = address(_vault_addr).call.value(balance).gas(gasleft())("");
        if(success) emit BalanceTransferedToVault(msg.sender, _vault_addr, balance);
    }

    function setVaultAddress(address payable new_address)
        public
        onlyOwner
        returns (address)
    {
        _vault_addr = new_address;
        return _vault_addr;
    }

 function setFreePeriod(uint256 nb_days)
        public
        onlyOwner
        returns (uint256)
    {
        free_period = nb_days;
        return free_period;
    }
    function getFreePeriod() public view onlyOwner returns (uint256) {
        return free_period;
    }

    function getBalance() public view onlyOwner returns (uint256) {
        return address(this).balance;
    }

    /* sets the price per day fee, in xDAI/USD cents */
    function setPricePerDay(uint256 fee) public onlyOwner returns (uint256) {
        price_day = fee;
        return price_day;
    }

    function getPricePerDay() public view onlyOwner returns (uint256) {
        return price_day;
    }

    /* sets the entry fee, in xDAI/USD cents */
    function setEntryFee(uint256 fee) public onlyOwner returns (uint256) {
        entry_fee = fee;
        return entry_fee;
    }

    function getEntryFee() public view onlyOwner returns (uint256) {
        return entry_fee;
    }

    function getVaultAddress() public view onlyOwner returns (address) {
        return _vault_addr;
    }

    function calculateFee(uint256 endDate) public view returns (uint256) {
        uint256 nb_days;
        uint256 total_price;
        if (endDate > now) nb_days = (endDate - now) / 60 / 60 / 24;
        if (nb_days < 1) nb_days = 1;
        if(nb_days < free_period) {
            total_price = 0;
            } else {
                total_price = ((price_day * nb_days) + entry_fee) * 10**16;//  16 , not 18 because our fees are in usd cents
            }
        return total_price; 
    }

    function migrate_one(uint256 index)
        public
        view
        onlyOwner
        returns (bytes memory)
    {
        return atomList[index];
    }

/*************
  KEYSTORE FN
*************/


    /*  function markAsOpened(string memory hashKey) public {
        require(msg.sender == worker_addr, "Unauthorized operation");
        if (atoms[hashKey]) open_atoms[hashKey] = true;
    }
    function hasBeenOpened(string memory hashKey)
        public
        view
        returns (bool)
    {
        return open_atoms[hashKey];
    }*/

    function checkHashKey(string memory hashKey)
        public
        view
        returns (bool)
    {
        return atoms[hashKey];
    }

    function makeAtom(
        string memory hashKey,
        string memory _public_content,
        string memory _timelocked_content,
        uint256 opening_date
    ) public payable {
        uint256 calculated_fee = calculateFee(opening_date);
        if (msg.value < calculated_fee) {
            revert("Insufficient Amount");
        }
        if (!checkIfExists(hashKey)) {
            registerAtom(hashKey,_public_content, _timelocked_content, opening_date, msg.value);
            emit PaymentReceived(msg.sender, _vault_addr, msg.value);
        } else {
            revert("TimeAtom already exists");
        }
    }
    
    function makeAtomERC20(
        string memory erc20_name,
        string memory name,
        string memory _public_content,
        string memory _timelocked_content,        
        uint256 opening_date,
        uint msgValue      
    ) public {        
         if (!checkIfExists(name)) {
        uint fee = calculateFee(opening_date);
        PayableByERC20.payWithERC20(erc20_name, fee, _vault_addr, msgValue);        
        registerAtom(name, _timelocked_content,_public_content, opening_date, msgValue);        
        }
    }

    function registerAtom(
        string memory hashKey,
        string memory _public_content,
        string memory _timelocked_content,
        uint256 opening_date,
        uint256 fee
    ) private {
        if (!checkIfExists(hashKey)) {
            // proceed with registering the atom
            registerAtomHandle(hashKey);
            public_contents[hashKey] = _public_content;
            timelocked_contents[hashKey] = _timelocked_content;
            atom_opening_date[hashKey] = opening_date;
            atomList.push(
                abi.encode(_timelocked_content, opening_date, hashKey)
            );
            emit AtomReady(msg.sender, fee, true);
        } else {
            revert("TimeAtom already already exists");
        }
    }

    function getAtom(string memory hashKey)
        public
        view
        returns (bytes memory)
    {
        if (atoms[hashKey]) {
            if (now > atom_opening_date[hashKey])
                return
                    abi.encode(
                        timelocked_contents[hashKey],
                        atom_opening_date[hashKey]
                    );
            else return abi.encode("0", atom_opening_date[hashKey]);
        } else return abi.encode("0", 0);
    }

    function getPublicContent(string memory hashKey)
        public
        view
        returns (bytes memory)
    {
        if (atoms[hashKey]) {            
            return  abi.encode(public_contents[hashKey],atom_opening_date[hashKey]);          
        } else return abi.encode("0", 0);
    }

    function checkIfExists(string memory hashKey) private view returns (bool) {
        return atoms[hashKey];
    }

    function registerAtomHandle(string memory hashKey)
        private
        returns (bool)
    {
        atoms[hashKey] = true;
    }
}
