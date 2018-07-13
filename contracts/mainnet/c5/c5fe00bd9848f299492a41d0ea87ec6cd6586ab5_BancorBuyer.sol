pragma solidity ^0.4.24;
//pragma experimental ABIEncoderV2;

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

// File: contracts/registry/BancorBuyer.sol

//pragma experimental ABIEncoderV2;




contract IMultiToken {
    function changeableTokenCount() external view returns(uint16 count);
    function tokens(uint256 i) public view returns(ERC20);
    function weights(address t) public view returns(uint256);
    function totalSupply() public view returns(uint256);
    function mint(address _to, uint256 _amount) public;
}


contract BancorBuyer {
    using SafeMath for uint256;

    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public tokenBalances; // [owner][token]

    function sumWeightOfMultiToken(IMultiToken mtkn) public view returns(uint256 sumWeight) {
        for (uint i = mtkn.changeableTokenCount(); i > 0; i--) {
            sumWeight += mtkn.weights(mtkn.tokens(i - 1));
        }
    }
    
    function allBalances(address _account, address[] _tokens) public view returns(uint256[]) {
        uint256[] memory tokenValues = new uint256[](_tokens.length);
        for (uint i = 0; i < _tokens.length; i++) {
            tokenValues[i] = tokenBalances[_account][_tokens[i]];
        }
        return tokenValues;
    }

    function deposit(address _beneficiary, address[] _tokens, uint256[] _tokenValues) payable external {
        if (msg.value > 0) {
            balances[_beneficiary] = balances[_beneficiary].add(msg.value);
        }

        for (uint i = 0; i < _tokens.length; i++) {
            ERC20 token = ERC20(_tokens[i]);
            uint256 tokenValue = _tokenValues[i];

            uint256 balance = token.balanceOf(this);
            token.transferFrom(msg.sender, this, tokenValue);
            require(token.balanceOf(this) == balance.add(tokenValue));
            tokenBalances[_beneficiary][token] = tokenBalances[_beneficiary][token].add(tokenValue);
        }
    }
    
    function withdrawInternal(address _to, uint256 _value, address[] _tokens, uint256[] _tokenValues) internal {
        if (_value > 0) {
            _to.transfer(_value);
            balances[msg.sender] = balances[msg.sender].sub(_value);
        }

        for (uint i = 0; i < _tokens.length; i++) {
            ERC20 token = ERC20(_tokens[i]);
            uint256 tokenValue = _tokenValues[i];

            uint256 tokenBalance = token.balanceOf(this);
            token.transfer(_to, tokenValue);
            require(token.balanceOf(this) == tokenBalance.sub(tokenValue));
            tokenBalances[msg.sender][token] = tokenBalances[msg.sender][token].sub(tokenValue);
        }
    }

    function withdraw(address _to, uint256 _value, address[] _tokens, uint256[] _tokenValues) external {
        withdrawInternal(_to, _value, _tokens, _tokenValues);
    }
    
    function withdrawAll(address _to, address[] _tokens) external {
        uint256[] memory tokenValues = allBalances(msg.sender, _tokens);
        withdrawInternal(_to, balances[msg.sender], _tokens, tokenValues);
    }

    // function approveAndCall(address _to, uint256 _value, bytes _data, address[] _tokens, uint256[] _tokenValues) payable external {
    //     uint256[] memory tempBalances = new uint256[](_tokens.length);
    //     for (uint i = 0; i < _tokens.length; i++) {
    //         ERC20 token = ERC20(_tokens[i]);
    //         uint256 tokenValue = _tokenValues[i];

    //         tempBalances[i] = token.balanceOf(this);
    //         token.approve(_to, tokenValue);
    //     }

    //     require(_to.call.value(_value)(_data));
    //     balances[msg.sender] = balances[msg.sender].add(msg.value).sub(_value);

    //     for (i = 0; i < _tokens.length; i++) {
    //         token = ERC20(_tokens[i]);
    //         tokenValue = _tokenValues[i];

    //         uint256 tokenSpent = tempBalances[i].sub(token.balanceOf(this));
    //         tokenBalances[msg.sender][token] = tokenBalances[msg.sender][token].sub(tokenSpent);
    //         token.approve(_to, 0);
    //     }
    // }
    
    function buyInternal(
        ERC20 token,
        address _exchange,
        uint256 _value,
        bytes _data
    ) 
        internal
    {
        uint256 tokenBalance = token.balanceOf(this);
        require(_exchange.call.value(_value)(_data));
        balances[msg.sender] = balances[msg.sender].sub(_value);
        tokenBalances[msg.sender][token] = tokenBalances[msg.sender][token]
            .add(token.balanceOf(this).sub(tokenBalance));
    }
    
    function mintInternal(
        IMultiToken _mtkn,
        uint256[] _notUsedValues
    ) 
        internal
    {
        uint256 totalSupply = _mtkn.totalSupply();
        uint256 bestAmount = uint256(-1);
        uint256 tokensCount = _mtkn.changeableTokenCount();
        for (uint i = 0; i < tokensCount; i++) {
            ERC20 token = _mtkn.tokens(i);

            // Approve XXX to mtkn
            uint256 thisTokenBalance = tokenBalances[msg.sender][token];
            uint256 mtknTokenBalance = token.balanceOf(_mtkn);
            _notUsedValues[i] = token.balanceOf(this);
            token.approve(_mtkn, thisTokenBalance);
            
            uint256 amount = totalSupply.mul(thisTokenBalance).div(mtknTokenBalance);
            if (amount < bestAmount) {
                bestAmount = amount;
            }
        }

        // Mint mtkn
        _mtkn.mint(msg.sender, bestAmount);
        
        for (i = 0; i < tokensCount; i++) {
            token = _mtkn.tokens(i);
            token.approve(_mtkn, 0);
            tokenBalances[msg.sender][token] = tokenBalances[msg.sender][token]
                .sub(token.balanceOf(this).sub(_notUsedValues[i]));
        }
    }
    
    // function buyAndMintInternal(
    //     IMultiToken _mtkn,
    //     uint256 _minAmount,
    //     address[] _tokens,
    //     address[] _exchanges,
    //     uint256[] _values,
    //     bytes[] _datas
    // ) 
    //     internal
    // {
    //     for (uint i = 0; i < _tokens.length; i++) {
    //         buyInternal(ERC20(_tokens[i]), _exchanges[i], _values[i], _datas[i]);
    //     }
    //     mintInternal(_mtkn, _minAmount, _values);
    // }
    
    ////////////////////////////////////////////////////////////////
    
    function buy1(
        address[] _tokens,
        address[] _exchanges,
        uint256[] _values,
        bytes _data1
    ) 
        payable
        public
    {
        balances[msg.sender] = balances[msg.sender].add(msg.value);
        buyInternal(ERC20(_tokens[0]), _exchanges[0], _values[0], _data1);
    }

    function buy2(
        address[] _tokens,
        address[] _exchanges,
        uint256[] _values,
        bytes _data1,
        bytes _data2
    ) 
        payable
        public
    {
        balances[msg.sender] = balances[msg.sender].add(msg.value);
        buyInternal(ERC20(_tokens[0]), _exchanges[0], _values[0], _data1);
        buyInternal(ERC20(_tokens[1]), _exchanges[1], _values[1], _data2);
    }
    
    function buy3(
        address[] _tokens,
        address[] _exchanges,
        uint256[] _values,
        bytes _data1,
        bytes _data2,
        bytes _data3
    ) 
        payable
        public
    {
        balances[msg.sender] = balances[msg.sender].add(msg.value);
        buyInternal(ERC20(_tokens[0]), _exchanges[0], _values[0], _data1);
        buyInternal(ERC20(_tokens[1]), _exchanges[1], _values[1], _data2);
        buyInternal(ERC20(_tokens[2]), _exchanges[2], _values[2], _data3);
    }
    
    function buy4(
        address[] _tokens,
        address[] _exchanges,
        uint256[] _values,
        bytes _data1,
        bytes _data2,
        bytes _data3,
        bytes _data4
    ) 
        payable
        public
    {
        balances[msg.sender] = balances[msg.sender].add(msg.value);
        buyInternal(ERC20(_tokens[0]), _exchanges[0], _values[0], _data1);
        buyInternal(ERC20(_tokens[1]), _exchanges[1], _values[1], _data2);
        buyInternal(ERC20(_tokens[2]), _exchanges[2], _values[2], _data3);
        buyInternal(ERC20(_tokens[3]), _exchanges[3], _values[3], _data4);
    }
    
    function buy5(
        address[] _tokens,
        address[] _exchanges,
        uint256[] _values,
        bytes _data1,
        bytes _data2,
        bytes _data3,
        bytes _data4,
        bytes _data5
    ) 
        payable
        public
    {
        balances[msg.sender] = balances[msg.sender].add(msg.value);
        buyInternal(ERC20(_tokens[0]), _exchanges[0], _values[0], _data1);
        buyInternal(ERC20(_tokens[1]), _exchanges[1], _values[1], _data2);
        buyInternal(ERC20(_tokens[2]), _exchanges[2], _values[2], _data3);
        buyInternal(ERC20(_tokens[3]), _exchanges[3], _values[3], _data4);
        buyInternal(ERC20(_tokens[4]), _exchanges[4], _values[4], _data5);
    }
    
    ////////////////////////////////////////////////////////////////
    
    function buy1mint(
        IMultiToken _mtkn,
        address[] _tokens,
        address[] _exchanges,
        uint256[] _values,
        bytes _data1
    ) 
        payable
        public
    {
        buy1(_tokens, _exchanges, _values, _data1);
        mintInternal(_mtkn, _values);
    }
    
    function buy2mint(
        IMultiToken _mtkn,
        address[] _tokens,
        address[] _exchanges,
        uint256[] _values,
        bytes _data1,
        bytes _data2
    ) 
        payable
        public
    {
        buy2(_tokens, _exchanges, _values, _data1, _data2);
        mintInternal(_mtkn, _values);
    }
    
    function buy3mint(
        IMultiToken _mtkn,
        address[] _tokens,
        address[] _exchanges,
        uint256[] _values,
        bytes _data1,
        bytes _data2,
        bytes _data3
    ) 
        payable
        public
    {
        buy3(_tokens, _exchanges, _values, _data1, _data2, _data3);
        mintInternal(_mtkn, _values);
    }
    
    function buy4mint(
        IMultiToken _mtkn,
        address[] _tokens,
        address[] _exchanges,
        uint256[] _values,
        bytes _data1,
        bytes _data2,
        bytes _data3,
        bytes _data4
    ) 
        payable
        public
    {
        buy4(_tokens, _exchanges, _values, _data1, _data2, _data3, _data4);
        mintInternal(_mtkn, _values);
    }
    
    function buy5mint(
        IMultiToken _mtkn,
        address[] _tokens,
        address[] _exchanges,
        uint256[] _values,
        bytes _data1,
        bytes _data2,
        bytes _data3,
        bytes _data4,
        bytes _data5
    ) 
        payable
        public
    {
        buy5(_tokens, _exchanges, _values, _data1, _data2, _data3, _data4, _data5);
        mintInternal(_mtkn, _values);
    }
    
    ////////////////////////////////////////////////////////////////
    
    function buyOne(
        address _token,
        address _exchange,
        uint256 _value,
        bytes _data
    ) 
        payable
        public
    {
        balances[msg.sender] = balances[msg.sender].add(msg.value);
        buyInternal(ERC20(_token), _exchange, _value, _data);
    }
    
    // function buyMany(
    //     address[] _tokens,
    //     address[] _exchanges,
    //     uint256[] _values,
    //     bytes[] _datas
    // ) 
    //     payable
    //     public
    // {
    //     balances[msg.sender] = balances[msg.sender].add(msg.value);
    //     for (uint i = 0; i < _tokens.length; i++) {
    //         buyInternal(ERC20(_tokens[i]), _exchanges[i], _values[i], _datas[i]);
    //     }
    // }

    // function buy(
    //     IMultiToken _mtkn, // may be 0
    //     address[] _exchanges, // may have 0
    //     uint256[] _values,
    //     bytes[] _datas
    // ) 
    //     payable
    //     public
    // {
    //     require(_mtkn.changeableTokenCount() == _exchanges.length, &quot;&quot;);

    //     balances[msg.sender] = balances[msg.sender].add(msg.value);
    //     for (uint i = 0; i < _exchanges.length; i++) {
    //         if (_exchanges[i] == 0) {
    //             continue;
    //         }

    //         ERC20 token = _mtkn.tokens(i);
            
    //         // ETH => XXX
    //         uint256 tokenBalance = token.balanceOf(this);
    //         require(_exchanges[i].call.value(_values[i])(_datas[i]));
    //         balances[msg.sender] = balances[msg.sender].sub(_values[i]);
    //         tokenBalances[msg.sender][token] = tokenBalances[msg.sender][token].add(token.balanceOf(this).sub(tokenBalance));
    //     }
    // }

    // function buyAndMint(
    //     IMultiToken _mtkn, // may be 0
    //     uint256 _minAmount,
    //     address[] _exchanges, // may have 0
    //     uint256[] _values,
    //     bytes[] _datas
    // ) 
    //     payable
    //     public
    // {
    //     buy(_mtkn, _exchanges, _values, _datas);

    //     uint256 totalSupply = _mtkn.totalSupply();
    //     uint256 bestAmount = uint256(-1);
    //     for (uint i = 0; i < _exchanges.length; i++) {
    //         ERC20 token = _mtkn.tokens(i);

    //         // Approve XXX to mtkn
    //         uint256 thisTokenBalance = tokenBalances[msg.sender][token];
    //         uint256 mtknTokenBalance = token.balanceOf(_mtkn);
    //         _values[i] = token.balanceOf(this);
    //         token.approve(_mtkn, thisTokenBalance);
            
    //         uint256 amount = totalSupply.mul(thisTokenBalance).div(mtknTokenBalance);
    //         if (amount < bestAmount) {
    //             bestAmount = amount;
    //         }
    //     }

    //     require(bestAmount >= _minAmount);
    //     _mtkn.mint(msg.sender, bestAmount);

    //     for (i = 0; i < _exchanges.length; i++) {
    //         token = _mtkn.tokens(i);
    //         token.approve(_mtkn, 0);
    //         tokenBalances[msg.sender][token] = tokenBalances[msg.sender][token].sub(token.balanceOf(this).sub(_values[i]));
    //     }
    // }

}