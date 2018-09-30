pragma solidity ^0.4.24;

contract FechHpbBallotAddr {
    
    address public contractAddr=0;
    
    string public funStr="0xc90189e4";
    
    //最近轮次的截止区块号 ,0 代表正在选举中，默认值为0；如果大于0，代表已经选举成功，
    //比如roundNum=2000,代表上一轮的截止区块号为2000
    uint public roundNum = 0;
    
    //合约拥有者
    address public owner;
    
    //合约管理员
    mapping (address => address) public adminMap;
    
   /**
    * 只有拥有者可以调用
   */
    modifier onlyOwner{
        require(msg.sender == owner);
        // Do not forget the "_;"! It will be replaced by the actual function
        // body when the modifier is used.
        _;
    }
	
    function transferOwnership(address newOwner) onlyOwner  public{
        owner = newOwner;
    }
   
   /**
    * 只有管理员可以调用
   */
    modifier onlyAdmin{
        require(adminMap[msg.sender] != 0);
        _;
    }
   
    /**
    * 添加管理员
   */
    function addAdmin(address addr) onlyOwner public{
        adminMap[addr] = addr;
    }
   
   /**
    * 删除管理员
   */
    function deleteAdmin(address addr) onlyOwner public{
        require(adminMap[addr] != 0);
        adminMap[addr]=0;
    }
   
    event SetContractAddr(address indexed from,address indexed _contractAddr);
    
    event SetFunStr(address indexed from,string indexed _funStr);
    
    event SetRoundNum(uint indexed _roundNum);
    
    constructor() public{
       owner = msg.sender;
       //设置默认管理员
	   adminMap[owner]=owner;
    }
    
    function setContractAddr(
        address _contractAddr
    ) onlyAdmin public{
        contractAddr=_contractAddr;
        emit SetContractAddr(msg.sender,_contractAddr);
    }
    
    //设置计算最近轮次的截止区块号 
    function setRoundNum(
        uint _roundNum
    ) onlyAdmin public{
        roundNum=_roundNum;
        emit SetRoundNum(_roundNum);
    }
   
   /**
     * 得到最近轮次的截止区块号
      */
    function getRoundNum(
    ) public constant returns(
        uint _roundNum
    ){
        return roundNum;
    }
    /**
     * 得到最获取智能合约地址
      */
    function getContractAddr(
    ) public constant returns(
        address _contractAddr
    ){
        return contractAddr;
    }
    
    function setFunStr(
        string _funStr
    ) onlyAdmin public{
        funStr=_funStr;
        emit SetFunStr(msg.sender,_funStr);
    }
    
    /**
     * 得到最获取智能合约调用方法
      */
    function getFunStr(
    ) public constant returns(
        string _funStr
    ){
        return funStr;
    }
}