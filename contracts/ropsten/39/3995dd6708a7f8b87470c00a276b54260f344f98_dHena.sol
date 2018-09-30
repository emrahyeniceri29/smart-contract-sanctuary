pragma solidity ^0.4.24;

// File: contracts\openzeppelin-solidity\contracts\ownership\Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
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
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

// File: contracts\openzeppelin-solidity\contracts\lifecycle\Pausable.sol

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() public onlyOwner whenNotPaused {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() public onlyOwner whenPaused {
    paused = false;
    emit Unpause();
  }
}

// File: contracts\openzeppelin-solidity\contracts\token\ERC20\ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: contracts\openzeppelin-solidity\contracts\math\SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

// File: contracts\openzeppelin-solidity\contracts\token\ERC20\BasicToken.sol

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) internal balances;

  uint256 internal totalSupply_;

  /**
  * @dev Total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev Transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value <= balances[msg.sender]);
    require(_to != address(0));

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

// File: contracts\openzeppelin-solidity\contracts\token\ERC20\ERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

// File: contracts\openzeppelin-solidity\contracts\token\ERC20\StandardToken.sol

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/issues/20
 * Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(_to != address(0));

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(
    address _spender,
    uint256 _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(
    address _spender,
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue >= oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

// File: contracts\openzeppelin-solidity\contracts\token\ERC20\MintableToken.sol

/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */
contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  modifier hasMintPermission() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(
    address _to,
    uint256 _amount
  )
    public
    hasMintPermission
    canMint
    returns (bool)
  {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() public onlyOwner canMint returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}

// File: contracts\openzeppelin-solidity\contracts\token\ERC20\BurnableToken.sol

/**
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
 */
contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

  /**
   * @dev Burns a specific amount of tokens.
   * @param _value The amount of token to be burned.
   */
  function burn(uint256 _value) public {
    _burn(msg.sender, _value);
  }

  function _burn(address _who, uint256 _value) internal {
    require(_value <= balances[_who]);
    // no need to require value <= totalSupply, since that would imply the
    // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure

    balances[_who] = balances[_who].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
  }
}

// File: contracts\AccountLockableToken.sol

contract AccountLockableToken is Ownable {
    mapping(address => bool) public lockStates;

    event LockAccount(address indexed lockAccount);
    event UnlockAccount(address indexed unlockAccount);

    /**
     * @dev Throws if called by locked account
     */
    modifier whenNotLocked() {
        require(!lockStates[msg.sender]);
        _;
    }

    /**
     * @dev Lock target account
     * @param _target Target account to lock
     */
    function lockAccount(address _target) public onlyOwner returns (bool) {
        require(_target != owner);
        require(!lockStates[_target]);

        lockStates[_target] = true;

        emit LockAccount(_target);

        return true;
    }

    /**
     * @dev Unlock target account
     * @param _target Target account to unlock
     */
    function unlockAccount(address _target) public onlyOwner returns (bool) {
        require(_target != owner);
        require(lockStates[_target]);

        lockStates[_target] = false;

        emit UnlockAccount(_target);

        return true;
    }
}

// File: contracts\WithdrawableToken.sol

contract WithdrawableToken is BasicToken, Ownable {
    using SafeMath for uint256;

    event Withdraw(address _from, address _to, uint256 _value);

    /**
     * @dev Withdraw the amount of tokens to onwer.
     * @param _from address The address which owner want to withdraw tokens form.
     * @param _value uint256 the amount of tokens to be transferred.
     */
    function withdraw(address _from, uint256 _value) public
        onlyOwner
        returns (bool)
    {
        require(_value <= balances[_from]);

        balances[_from] = balances[_from].sub(_value);
        balances[owner] = balances[owner].add(_value);

        emit Withdraw(_from, owner, _value);

        return true;
    }

    /**
     * @dev Withdraw the amount of tokens to another.
     * @param _from address The address which owner want to withdraw tokens from.
     * @param _to address The address which owner want to transfer to.
     * @param _value uint256 the amount of tokens to be transferred.
     */
    function withdrawFrom(address _from, address _to, uint256 _value) public
        onlyOwner
        returns (bool)
    {
        require(_value <= balances[_from]);
        require(_to != address(0));

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);

        emit Withdraw(_from, _to, _value);

        return true;
    }
}

// File: contracts\openzeppelin-solidity\contracts\math\Math.sol

/**
 * @title Math
 * @dev Assorted math operations
 */
library Math {
  function max64(uint64 _a, uint64 _b) internal pure returns (uint64) {
    return _a >= _b ? _a : _b;
  }

  function min64(uint64 _a, uint64 _b) internal pure returns (uint64) {
    return _a < _b ? _a : _b;
  }

  function max256(uint256 _a, uint256 _b) internal pure returns (uint256) {
    return _a >= _b ? _a : _b;
  }

  function min256(uint256 _a, uint256 _b) internal pure returns (uint256) {
    return _a < _b ? _a : _b;
  }
}

// File: contracts\MilestoneLockToken.sol

contract MilestoneLockToken is StandardToken, Ownable {
    using Math for uint256;
    using SafeMath for uint256;

    struct Milestone {
        uint256 kickOff;
        uint256[] periods;
        uint8[] percentages;
    }

    struct LockedBalance {
        uint8 milestone;
        uint256 lockedBalanceStandard;
    }

    uint256 constant MAX_PERCENTAGE = 100;

    mapping(uint8 => Milestone) internal milestones;
    mapping(address => LockedBalance) internal lockedBalances;

    event SetMilestoneKickOff(uint8 milestone, uint256 kickOff);
    event MilestoneAdded(uint8 milestone);
    event MilestoneRemoved(uint8 milestone);
    event PolicyAdded(uint8 milestone, uint256 period, uint8 percent);
    event PolicyRemoved(uint8 milestone, uint256 period);

    /**
     * @dev Transfer token for a specified address when if has enough available unlock balance.
     * @param _to The address to transfer to.
     * @param _value The amount to be transferred.
     */
    function transfer(address _to, uint256 _value) public
        returns (bool)
    {
        require(getAvailableBalance(msg.sender) >= _value);

        return super.transfer(_to, _value);
    }

    /**
     * @dev Transfer tokens from one address to anther when if has enough available unlock balance.
     * @param _from address The address which you want to send tokens from.
     * @param _to address The address which you want to transfer to.
     * @param _value uint256 the amount of tokens to be transferred.
     */
    function transferFrom(address _from, address _to, uint256 _value) public
        returns (bool)
    {
        require(getAvailableBalance(_from) >= _value);

        return super.transferFrom(_from, _to, _value);
    }

    /**
     *
     */
    function distributeWithMilestone(address _to, uint256 _value, uint8 _milestone) public
        onlyOwner
        returns (bool)
    {
        require(_to != address(0));
        require(_value <= balances[owner]);
        require(_milestone > 0);

        LockedBalance storage lockedBalance = lockedBalances[_to];

        require(lockedBalance.milestone != 0);

        balances[_to] = balances[_to].add(_value);
        lockedBalance.lockedBalanceStandard = _value;

        emit Transfer(owner, _to, _value);

        return true;
    }

    /**
     * @dev add milestone
     * @param _milestone number of the milestone you want to add
     * @param _periods periods of the milestone you want to add
     * @param _percentages unlock percentages of the milestone you want to add
     */
    function addMilestone(uint8 _milestone, uint256[] _periods, uint8[] _percentages) public
        onlyOwner
        returns (bool)
    {
        require(_milestone > 0);
        require(_periods.length > 0);
        require(_percentages.length > 0);
        require(_periods.length == _percentages.length);

        Milestone storage milestone = milestones[_milestone];

        require(milestone.periods.length == 0);

        milestone.periods = _periods;
        milestone.percentages = _percentages;

        emit MilestoneAdded(_milestone);

        return true;
    }

    /**
     * @dev remove milestone
     * @param _milestone number of the milestone you want to remove
     */
    function removeMilestone(uint8 _milestone) public
        onlyOwner
        returns (bool)
    {
        require(_milestone > 0);

        delete milestones[_milestone];

        emit MilestoneRemoved(_milestone);

        return true;
    }

    /**
     * @dev get milestone information.
     * @param _milestone number of milestone.
     */
    function getMilestoneInfo(uint8 _milestone) public
        view
        returns (uint256, uint256[], uint8[])
    {
        require(_milestone > 0);

        Milestone storage milestone = milestones[_milestone];

        return (milestone.kickOff, milestone.periods, milestone.percentages);
    }

    /**
     * @dev remove policy from milestone.
     * @param _period period of target policy.
     */
    function removePolicy(uint8 _milestone, uint256 _period) public
        onlyOwner
        returns (bool)
    {
        require(_milestone > 0);

        Milestone storage milestone = milestones[_milestone];
        for (uint256 i = 0; i < milestone.periods.length; i++) {
            if (milestone.periods[i] == _period) {
                delete milestone.periods[i];
                delete milestone.percentages[i];

                emit PolicyRemoved(_milestone, _period);

                return true;
            }
        }

        revert();

        return false;
    }

    /**
     * @dev add policy to milestone.
     * @param _milestone number of milestone.
     * @param _period period of policy.
     * @param _percentage percentage of unlocking when reaching policy.
     */
    function addPolicy(uint8 _milestone, uint256 _period, uint8 _percentage) public
        onlyOwner
        returns (bool)
    {
        require(_milestone > 0);

        Milestone storage milestone = milestones[_milestone];

        for (uint256 i = 0; i < milestone.periods.length; i++) {
            if (milestone.periods[i] == _period) {
                revert();

                return false;
            }
        }

        milestone.periods.push(_period);
        milestone.percentages.push(_percentage);

        emit PolicyAdded(_milestone, _period, _percentage);

        return true;
    }

    /**
     * @dev set account&#39;s milestone.
     * @param _milestone number of milestone for LockedBalance applyed.
     * @param _account address for milestone applyed.
    */
    function setAccountMilestone(address _account, uint8 _milestone) internal
        onlyOwner
        returns (bool)
    {
        require(_milestone > 0);
        require(_account != address(0));

        lockedBalances[_account].milestone = _milestone;

        return true;
    }

    /**
     * @dev remove LockedBalance&#39;s milestone.
     * @param _account address for applyed milestone remove.
     */
    function removeAccountMilestone(address _account) public
        onlyOwner
        returns (bool)
    {
        require(_account != address(0));

        LockedBalance storage lockedBalance = lockedBalances[_account];

        require(lockedBalance.milestone > 0);

        lockedBalances[_account].milestone = 0;
        lockedBalances[_account].lockedBalanceStandard = 0;

        return true;
    }

    /**
     * @dev locked accounts balance info
     * @param _account address for locked balance information
     */
    function getLockedBalance(address _account) public view
        returns (uint8, uint256, uint256)
    {
        LockedBalance storage lockedBalance = lockedBalances[_account];

        return (
            lockedBalance.milestone,
            lockedBalance.lockedBalanceStandard,
            calculateLockedBalance(_account)
        );
    }

    /**
     * @dev available unlock balance
     * @param _account address for request available unlock balance
     */
    function getAvailableBalance(address _account) public view
        returns (uint256)
    {
        return balances[_account].sub(calculateLockedBalance(_account));
    }

    /**
     * @dev get current milestone&#39;s locked balance percentage
     * @param _milestone number of milestone for calculate locked percentage
     */
    function calculateLockedPercentage(uint8 _milestone) internal view
        returns (uint256)
    {
        Milestone storage milestone = milestones[_milestone];

        if (milestone.periods.length == 0) {
            return 0;
        }
        
        if (milestone.kickOff < now) {
            return MAX_PERCENTAGE;
        }

        uint256 unlockedPercentage = 0;
        for (uint256 i = 0; i < milestone.periods.length; ++i) {
            if (milestone.kickOff + milestone.periods[i] <= now) {
                unlockedPercentage.add(uint256(milestone.percentages[i]));
            }
        }

        if (unlockedPercentage > MAX_PERCENTAGE) {
            return 0;
        }

        return MAX_PERCENTAGE - unlockedPercentage;
    }

    function calculateLockedBalance(address _account) internal view
        returns (uint256)
    {
        LockedBalance storage lockedBalance = lockedBalances[_account];
        if (lockedBalance.milestone == 0) {
            return 0;
        }

        uint256 lockedPercentage = calculateLockedPercentage(lockedBalance.milestone);
        return lockedBalance.lockedBalanceStandard.sub(MAX_PERCENTAGE).mul(lockedPercentage);
    }
}

// File: contracts\dHena.sol

/**
 * @title Hena token
 */
contract dHena is
    MilestoneLockToken,
    MintableToken,
    BurnableToken,
    Pausable,
    AccountLockableToken,
    WithdrawableToken
{
    uint256 constant MAX_SUFFLY = 1500000000;

    string public name;
    string public symbol;
    uint8 public decimals;

    constructor() public {
        name = "dHena";
        symbol = "DHENA";
        decimals = 18;
        totalSupply_ = MAX_SUFFLY * 10 ** uint(decimals);

        balances[owner] = totalSupply_;

        emit Transfer(address(0), owner, totalSupply_);
    }

    /**
     * @dev Transfer token for a specified address when if not paused and not locked account
     * @param _to The address to transfer to.
     * @param _value The amount to be transferred.
     */
    function transfer(address _to, uint256 _value) public
        whenNotPaused
        whenNotLocked
        returns (bool)
    {
        return super.transfer(_to, _value);
    }

    /**
     * @dev Transfer tokens from one address to anther when if not paused and not locked account
     * @param _from address The address which you want to send tokens from.
     * @param _to address The address which you want to transfer to.
     * @param _value uint256 the amount of tokens to be transferred.
     */
    function transferFrom(address _from, address _to, uint256 _value) public
        whenNotPaused
        whenNotLocked
        returns (bool)
    {
        require(!lockStates[_from]);

        return super.transferFrom(_from, _to, _value);
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender when if not paused and not locked account
     * @param _spender address which will spend the funds.
     * @param _addedValue amount of tokens to increase the allowance by.
     */
    function increaseApproval(address _spender, uint256 _addedValue) public
        whenNotPaused
        whenNotLocked
        returns (bool)
    {
        return super.increaseApproval(_spender, _addedValue);
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     * @param _spender address which will spend the funds.
     * @param _subtractedValue amount of tokens to decrease the allowance by.
     */
    function decreaseApproval(address _spender, uint256 _subtractedValue) public
        whenNotPaused
        whenNotLocked
        returns (bool)
    {
        return super.decreaseApproval(_spender, _subtractedValue);
    }

    /**
     * @dev Distribute the amount of tokens to owner&#39;s balance.
     * @param _to The address to transfer to.
     * @param _value The amount to be transffered.
     */
    function distribute(address _to, uint256 _value) public
        onlyOwner
        returns (bool)
    {
        require(_to != address(0));
        require(_value > 0 && _value <= balances[owner]);

        balances[owner] = balances[owner].sub(_value);
        balances[_to] = balances[_to].add(_value);

        emit Transfer(owner, _to, _value);

        return true;
    }
}