pragma solidity ^0.4.19;

//deployed on Ropsten at: 0xd29d27cfacf7b77a16edac7c2cddf07dc4a603b8 
//.8 Ether stored under transNonce 1
//This one works:
//json(https://ropsten.infura.io/).result
// {&quot;jsonrpc&quot;:&quot;2.0&quot;,&quot;id&quot;:3,&quot;method&quot;:&quot;eth_call&quot;,&quot;params&quot;:[{&quot;to&quot;:&quot;0xd29d27cfacf7b77a16edac7c2cddf07dc4a603b8&quot;,&quot;data&quot;:&quot;0xc16fe9070000000000000000000000000000000000000000000000000000000000000001&quot;}, &quot;latest&quot;]}
contract TestQuery{
  struct Details{
    uint amount;
    address owner;
    uint transferId;
  }

  uint transNonce;
    event Locked(address _from, uint _value);

  mapping(uint => Details) transferDetails; //maps a transferId to an amount
    mapping(address => uint[]) transferList; //list of all transfers from an address;

  function lockforTransfer() payable public returns(uint){
    require(msg.value > 0);
        transNonce += 1;
    transferDetails[transNonce] = Details({
      amount:msg.value,
      owner:msg.sender,
      transferId:transNonce
      });
    transferList[msg.sender].push(transNonce);
    return(transNonce);
  }

  function getTransfer(uint _transferId) public view returns(uint,address,uint){
    Details memory _locked = transferDetails[_transferId];
    return(_locked.amount,_locked.owner,_locked.transferId);
  }

}