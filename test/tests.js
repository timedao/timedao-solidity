const { expect} = require('chai');
// Import utilities from Test Helpers
const { BN, expectEvent, expectRevert } = require('@openzeppelin/test-helpers');
const ganache = require('ganache-cli');
const Web3 = require ('web3');
const provider = ganache.provider();
const web3 = new Web3(provider);


// Load compiled artifacts
const Box = artifacts.require('TimeAtom');
const Erc20 = artifacts.require("simpleERC20");
// Start test block
contract('TimeAtom', accounts => {

  beforeEach('setup contract for each test', async () => {
    instance = await Box.deployed();
    instanceErc = await Erc20.deployed();  
});
 
  // Test cases
  it('sets a price per day and retrieves it', async function () {       
    let res = await instance.setPricePerDay(1);   
    res1 = await instance.getPricePerDay();     
    assert.equal(res1.toString(),"1","Incorrect return:"+res1.toString()) ;   
  });


  it('sets and gets Vault address', async function () {     
    let vault_addr = await instance.getVaultAddress();
    await instance.setVaultAddress("0x0000000000000000000000000000000000000000"); 
    let new_vault_addr = await instance.getVaultAddress();
    let res = await instance.setVaultAddress(vault_addr);
    let res1 = await instance.getVaultAddress();
    assert.equal(vault_addr,res1,"Incorrect address")   
    
  });

    it('adds a new ERC20 to whitelist and retrieves it', async function () {  
    res = await instance.addEditERC20Token("FakeDAI",instanceErc.address);
    res1 = await  instance.getERC20TokenAddress("FakeDAI");   
    assert.equal(  res1.valueOf(),instanceErc.address,"Incorrect return:"+res1.valueOf()) ;         
  });

  it('adds a new ERC20 to whitelist then removes it', async function () {  
    res = await instance.addEditERC20Token("FakeDAI",instanceErc.address);
    res0 = await  instance.removeERC20Token("FakeDAI");  
    res1 = await  instance.getERC20TokenAddress("FakeDAI");
    assert.equal(  res1.valueOf(),0,"Incorrect return:"+res1.valueOf()) ;         
  });


  it('calculates the fees for 15 days', async function () {  
    await instance.setPricePerDay(1);
    await instance.setEntryFee(5);
    await  instance.setFreePeriod(1);  
    var dateplus15days =  new Date().getTime() + 15*24*60*60*1000;
    let timestamp = Math.round(dateplus15days / 1000)
    res1 = await instance.calculateFee(timestamp) 
    assert.equal(parseInt(res1.toString()),200000000000000000,"Incorrect return:"+res1.toString()) ;  
  });

  it('Checks free period discount', async function () {  
    await instance.setPricePerDay(1);
    await instance.setEntryFee(5);
    await  instance.setFreePeriod(100);  
    var dateplus15days =  new Date().getTime() + 15*24*60*60*1000;
    let timestamp = Math.round(dateplus15days / 1000)
    res1 = await instance.calculateFee(timestamp)  
    assert.equal(parseInt(res1.toString()),0,"Incorrect return:"+res1.toString()) ;  
  });

  it('creates an entry', async function () {  
    entry = { name : "Test"+(Math.random()*1000), pk:"XXX"+(Math.random()*1000),pub:"XXX"+(Math.random()*1000)}
     
    await instance.setPricePerDay(1);
    await instance.setEntryFee(5);
    await  instance.setFreePeriod(1);  
    var dateplus15days =  new Date().getTime()-10; 
    //+ 15*24*60*60*1000;
    timestamp = Math.round(dateplus15days / 1000)
    entry.opening_date = timestamp;
    res0 = await instance.calculateFee(timestamp) 
    res1 = await instance.makeAtom(entry.name,entry.pub,entry.pk,timestamp,{gas:4500000,gasPrice:10000000000,value:parseInt(res0.toString())});
    expectEvent(res1, 'AtomReady', { _value: true });    
  
  });

  it('checks the existence of an entry', async function () {   
    res2 = await instance.checkHashKey(entry.name);
    assert.equal(res2.valueOf(),true,"should be true") ; 
  }); 




  it('getPublicContent : gets the previous Wallet\'s public keys', async function () { 
    res1 = await instance.getPublicContent(entry.name);
    let result = web3.eth.abi.decodeParameters(
      [
        {
          type: "string",
          name: "public_keys",
        },
        {
          name: "opening_date",
          type: "uint",
        },
      ],
      res1
    );    
    assert.equal(result.public_keys,entry.pub,"Incorrect return:") ;
  }); 


  it('getAtom : gets the previous record and checks its opening date', async function () { 
    res1 = await instance.getAtom(entry.name);
    let result = web3.eth.abi.decodeParameters(
      [
        {
          type: "string",
          name: "private_keys",
        },
        {
          name: "opening_date",
          type: "uint",
        },
      ],
      res1
    );    
    assert.equal(result.opening_date,timestamp,"Incorrect return:") ;
  }); 

  it('creates an entry using ERC20', async function () {  
    res = await instance.addEditERC20Token("FakeDAI",instanceErc.address);
    await instance.setPricePerDay(1);
    await instance.setEntryFee(5);
    await  instance.setFreePeriod(1); 

    entryERC = { name : "Test"+(Math.random()*1000), pk:"XXX",pub:"XXX"}
    var dateplus15days =  new Date().getTime() + 2*24*60*60*1000;
    let timestamp = Math.round(dateplus15days / 1000)
    entryERC.opening_date = timestamp;
    res0 = await instance.calculateFee(timestamp);   
    
    await instanceErc.approve(instance.address, res0.toString(),{from:accounts[0]}); 
    let allowance = await instanceErc.allowance(accounts[0],instance.address);    
    res4 = await instanceErc.balanceOf(accounts[0]);     
    res1 = await instance.makeAtomERC20("FakeDAI",entryERC.name,entryERC.pub,entryERC.pk,timestamp,res0,{from:accounts[0]})  
    expectEvent(res1, 'AtomReady', { _value: true });       
  });

  it('adds a new ERC20 to whitelist then gets its balance', async function () {  
    res = await instance.addEditERC20Token("FakeDAI",instanceErc.address);   
    await instanceErc.transfer(instance.address,10);
    res1 = await  instance.getERC20TokenBalance("FakeDAI"); 
    assert.equal(  res1.toString(),10,"Incorrect return:"+res1.valueOf()) ;         
  });

  it('transfers the ETH balance to Vault', async function () {  
    let balance = await instance.getBalance();   
    let vault_addr = await instance.getVaultAddress(); 
    res1 = await instance.transferBalanceToVault();
    expectEvent(res1, 'BalanceTransferedToVault', { amount: balance });   
  });

  it('checks the migration function', async function () {   
    res2 = await instance.migrate_one(0);
    let receipt = web3.eth.abi.decodeParameters(
      [ {"type":"string",
         "name": "private_keys"            
      },{
         "name": "opening_date",
         "type":"uint"
      },
      {
         "name": "name",
         "type":"string"
      }, ],res2);     
     
    assert.equal(receipt.private_keys+receipt.name+receipt.opening_date
      ,entry.pk+entry.name+entry.opening_date
      ,"Incorrect") ; 
  }); 
});