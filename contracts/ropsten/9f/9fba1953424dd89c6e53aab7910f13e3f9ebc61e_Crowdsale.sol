pragma solidity ^0.4.13;
 
//Убираем отправку нам токенов в конце. Отправляем одновременно с отправкой инвестору. И убираем остановку печати.
//V5 Печатаем инвестору и столько же команде
//V6 Убираем HardCap
//V7 убираем дату окончания
//V9 добавляем изменяемую переменную. Меняется только владельцем контракта (ChangeEmissionRate) и показывает всем (ShowEmissionRate) в разделе Crowdsale
//V10 в ChangeEmissionRate добавляем запись в лог
//V11 сохраняем в переменную количество токенов, выданных в обмен на деньги и вносим это значение в лог.
//V12 меняем формулировку - убираем kessak
//V13 пробуем вставить не log, а event в ChangeRate
//V14 создаем событие для суммирования проданных токенов
//V15 вводим условие, которое отслеживает произведенную эмиссию и если хотят купить больше, то отказывает и возвращает деньги
//V16 вводим условие, которое отслеживает как в V15, но 2 раза и принимает деньги. Остаток возвращает.
//V17 исправляем баги в передаче данных в логи и делаем уменьшение выдаваемых токенов на 1 Эфир (увеличение стоимости)
//V18 исправлен баг с уменьшением выдаваемых токенов во второй итерации.
//V19 делаем все с SafeMath


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}
 
/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}
 
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }
 
  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }
 
  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }
 
  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
  
}
 
/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances. 
 */
contract BasicToken is ERC20Basic {
    
  using SafeMath for uint256;
 
  mapping(address => uint256) balances;
 
  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }
 
  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of. 
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }
 
}
 
/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {
 
  mapping (address => mapping (address => uint256)) allowed;
 
  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amout of tokens to be transfered
   */
  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
    var _allowance = allowed[_from][msg.sender];
 
    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // require (_value <= _allowance);
 
    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }
 
  /**
   * @dev Aprove the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) returns (bool) {
 
    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));
 
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }
 
  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifing the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }
 
}
 
/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    
  address public owner;
 
  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() {
    owner = msg.sender;
  }
 
  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
 
  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner {
    require(newOwner != address(0));      
    owner = newOwner;
  }

 
}
 
/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/zeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */
 
contract MintableToken is StandardToken, Ownable {
    
  event Mint(address indexed to, uint256 amount);
  
  //event MintFinished();
 
  //bool public mintingFinished = false;
 
  //modifier canMint() {
  //  require(!mintingFinished);
  //  _;
  //}
 
  /**
   * @dev Function to mint tokens
   * @param _to The address that will recieve the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _amount) onlyOwner returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    return true;
  }
 
  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  //function finishMinting() onlyOwner returns (bool) {
  //  mintingFinished = true;
  //  MintFinished();
  //  return true;
  //}
  
}
 
contract iUventaToken is MintableToken {
    
    string public constant name = "iUventa019";
    
    string public constant symbol = "iUv019";
    
    uint32 public constant decimals = 18;
    
}
 
 
contract Crowdsale is Ownable {
    
    using SafeMath for uint;
    
    address multisig;
 
  //  uint restrictedPercent;
 
    address restricted;
 
    iUventaToken public token = new iUventaToken();
 
    uint start;
    
  // uint period;
 
  //  uint hardcap;
 
    uint emissionRate;
    uint TokenSumm;
    uint Emission;
    uint EmissionGrowthCoefficient;
    uint EmissionRateCoefficient;
 
    //uint token_to_mint;
 
    function Crowdsale() {
        multisig = 0x26c36256d607A30C758995EF8CD062Ab28d2d527;
        restricted = 0xA47DEb9A9dbAab3EA48398D97071f27285B241e4;
    //    restrictedPercent = 50;

    //    StartEmissionRate = 10000000000000000000000; // сколько токенов выдаем за 1 Эфир
    //    StartEmission = 10000000000000000000000;    // какое количество токенов выпускаем в первом цикле
    //    EmissionGrowthCoefficient = 10; // коэффициент роста эмиссии. потом к нему нужно будет прибавить 100 и разделить на 100
    //    EmissionRateCoefficient = 5; // коэффициент уменьшения кол-ва выдаваемых токенов за 1 Эфир

        // Time of start and stop. Needs to change
        
        start = 1500379200;
    //    period = 500;
    //    hardcap = 10000000000000000000000;
    }
 
    modifier saleIsOn() {
      require(now > start);
      _;
    }
  
    //modifier isUnderHardCap() {
    //    require(multisig.balance <= hardcap);
    //    _;
    //}
 
    //function finishMinting() public onlyOwner {
    //    uint issuedTokenSupply = token.totalSupply();
    //    uint restrictedTokens = issuedTokenSupply.mul(restrictedPercent).div(100 - restrictedPercent);
    //    token.mint(restricted, restrictedTokens);
    //    token.finishMinting();
    //}
 

    event MintedTokens (uint _value);
    event EmissionGrows (uint _value);
    event EmissionRateDecrease (uint _value);

    function createTokens() saleIsOn payable {
    uint tokens = emissionRate.mul(msg.value).div(1 ether);
    uint hundred = 100;


    uint DeltaEmission = (Emission).sub(TokenSumm); // сколько осталось выпустить токенов на данном этапе

// если мы собираемся выпустить токенов меньше или столько же, сколько осталось довыпустить в этом шаге. Потом они уже выпускаться не будут и деньги вернутся

      if (DeltaEmission > tokens) {
        multisig.transfer(msg.value);
        //uint tokens = emissionRate.mul(msg.value).div(1 ether);
        TokenSumm = (TokenSumm).add(tokens);
        token.mint(msg.sender, tokens);
        token.mint(restricted, tokens);
        MintedTokens(tokens);
      }
      else if (DeltaEmission == tokens){
        multisig.transfer(msg.value);
       // TokenSumm = (TokenSumm).add(tokens);
        token.mint(msg.sender, tokens);
        token.mint(restricted, tokens);
        MintedTokens(tokens);   
        Emission=Emission.mul(EmissionGrowthCoefficient.add(hundred)).div(hundred);
        EmissionGrows(Emission);
        emissionRate = emissionRate.mul((hundred).sub(EmissionRateCoefficient)).div(hundred);
        EmissionRateDecrease(emissionRate);        
        TokenSumm=0;
      }
      else {
        token.mint(msg.sender, DeltaEmission);
        token.mint(restricted, DeltaEmission);
        MintedTokens(DeltaEmission); // исправлено - в логи шла не та цифра
        Emission=Emission.mul(EmissionGrowthCoefficient.add(hundred)).div(hundred);
        EmissionGrows(Emission);
        //TokenSumm=0;

        uint UsedValue = DeltaEmission.mul(1 ether).div(emissionRate); // считаем на какую сумму выпустили токенов
        // вот где-то здесь нужно будет менять стоимость токенов. пока что она постоянная

        uint balance = msg.value.sub(UsedValue);
        emissionRate = emissionRate.mul((hundred).sub(EmissionRateCoefficient)).div(hundred);
        EmissionRateDecrease(emissionRate);

        tokens = emissionRate.mul(balance).div(1 ether); // это сколько токенов мы должны на втором цикле выпустить
        DeltaEmission = Emission; // сколько осталось выпустить токенов на следующем этапе
        
        if (DeltaEmission > tokens) {
          multisig.transfer(msg.value);
           //uint tokens = emissionRate.mul(msg.value).div(1 ether);
          TokenSumm = tokens;
          token.mint(msg.sender, tokens);
          token.mint(restricted, tokens);
          MintedTokens(tokens);
        }
        else if (DeltaEmission == tokens){
          multisig.transfer(msg.value);
          //TokenSumm = TokenSumm.add(tokens);
          token.mint(msg.sender, tokens);
          token.mint(restricted, tokens);
          MintedTokens(tokens);   
          Emission=Emission.mul(EmissionGrowthCoefficient.add(hundred)).div(hundred);
          EmissionGrows(Emission);
          emissionRate = emissionRate.mul((hundred).sub(EmissionRateCoefficient)).div(hundred);
          EmissionRateDecrease(emissionRate);          
          TokenSumm=0;
        }
        else {
          uint UsedValue2 = DeltaEmission.mul(1 ether).div(emissionRate); // считаем на какую сумму выпустили токенов во второй ступени
          multisig.transfer(UsedValue2.add(UsedValue)); // отправляем нам сумму на которую выпустили токенов
          msg.sender.transfer((msg.value).sub(UsedValue2).sub(UsedValue)); // возвращаем оставшиесы деньги
          token.mint(msg.sender, DeltaEmission);
          token.mint(restricted, DeltaEmission);  
          MintedTokens(DeltaEmission); // исправлено
          Emission=Emission.mul((EmissionGrowthCoefficient).add(hundred)).div(hundred);
          EmissionGrows(Emission);
          emissionRate = emissionRate.mul((hundred).sub(EmissionRateCoefficient)).div(hundred);
          EmissionRateDecrease(emissionRate);          
          TokenSumm=0;
        }

        
      }

//      else if(){msg.sender.transfer(msg.value);}
  
        
    }
 
    function() external payable {
        createTokens();
    }

    event ChangeRate (
    uint _value);

    event ChangeEmission (
    uint _value);
    event ChangeEmissionCoefficient (
    uint _value);    
    event ChangeRateCoefficient (
    uint _value);     

    function ChangeEmissionRate(uint n) onlyOwner {
//      require(newOwner != address(0));      
      emissionRate = n;
      ChangeRate(emissionRate);
    }

    function ChangeEmissionSumm(uint n) onlyOwner {
//      require(newOwner != address(0));      
      Emission = n;
      ChangeEmission(Emission);
    }

//    function ShowEmissionRate(uint n) returns (uint) { 
//      return emissionRate;
//    }
    function ChangeEmissionGrowthCoefficient(uint n) onlyOwner {
//      require(newOwner != address(0));      
      EmissionGrowthCoefficient = n;
      ChangeEmissionCoefficient(EmissionGrowthCoefficient);
    }  
    function ChangeEmissionRateCoefficient(uint n) onlyOwner {
//      require(newOwner != address(0));      
      EmissionRateCoefficient = n;
      ChangeRateCoefficient(EmissionRateCoefficient);
    }    
    
}