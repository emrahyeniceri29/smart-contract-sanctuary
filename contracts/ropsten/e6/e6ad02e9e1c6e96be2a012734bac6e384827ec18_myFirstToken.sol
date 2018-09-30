pragma solidity ^0.4.24;

interface ERC20{
    
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner,address spender) public constant returns (uint remaining);
    function transfer(address to,uint tokens) public returns (bool success);
    function approve(address spender,uint tokens) public returns (bool success);
    function transferFrom(address from,address to,uint tokens) public returns (bool success);
    event Transfer(address indexed from , address indexed to ,uint tokens );
    event Approval(address indexed tokenOwner,address indexed spender ,uint tokens);
    
}
contract myFirstToken is ERC20{
    
    string public name;
    string public symbol;
    uint8 public decimals;
    
    uint256 public _totalSupply;
    address public _tokenOwner;
    uint256 public _availableSupply;
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    
    function myFirstToken()
    {
        name ="Mark first Real token";
        symbol = "NAGA";
        decimals = 18;
        _totalSupply =1000000;
        _tokenOwner = msg.sender;
        balances[_tokenOwner] = _totalSupply;
        _availableSupply =0;
    }
    
    
    function totalSupply() public constant returns (uint){
        return _totalSupply;
    }
    function balanceOf(address tokenOwner) public constant returns (uint balance){
        return balances[tokenOwner];
    }
    
    function allowance(address tokenOwner,address spender) public constant returns (uint remaining){
        return allowed[tokenOwner][spender];
    }
    function transfer(address to,uint tokens) public returns (bool success){
        balances[msg.sender] -=tokens;
        balances[to] +=tokens;
        return true;
        
    }
    function approve(address spender,uint tokens) public returns (bool success){
        allowed[msg.sender][spender]=tokens;
        
    }
    function transferFrom(address from,address to,uint tokens) public returns (bool success){
        balances[from] -=tokens;
        balances[to]+=tokens;
        allowed[from][msg.sender] -=tokens;
        return true;
    }

    
}