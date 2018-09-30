pragma solidity ^0.4.24;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

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
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

/**
 * @title SafeMath v0.1.9
 * @dev Math operations with safety checks that throw on error
 * change notes:  original SafeMath library from OpenZeppelin modified by Inventor
 * - added sqrt
 * - added sq
 * - added pwr 
 * - changed asserts to requires with error log outputs
 * - removed div, its useless
 */
library SafeMath {
    
    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) 
        internal 
        pure 
        returns (uint256 c) 
    {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        require(c / a == b, "SafeMath mul failed");
        return c;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b)
        internal
        pure
        returns (uint256) 
    {
        require(b <= a, "SafeMath sub failed");
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b)
        internal
        pure
        returns (uint256 c) 
    {
        c = a + b;
        require(c >= a, "SafeMath add failed");
        return c;
    }
    
    /**
     * @dev gives square root of given x.
     */
    function sqrt(uint256 x)
        internal
        pure
        returns (uint256 y) 
    {
        uint256 z = ((add(x,1)) / 2);
        y = x;
        while (z < y) 
        {
            y = z;
            z = ((add((x / z),z)) / 2);
        }
    }
    
    /**
     * @dev gives square. multiplies x by x
     */
    function sq(uint256 x)
        internal
        pure
        returns (uint256)
    {
        return (mul(x,x));
    }
    
    /**
     * @dev x to the power of y 
     */
    function pwr(uint256 x, uint256 y)
        internal 
        pure 
        returns (uint256)
    {
        if (x==0)
            return (0);
        else if (y==0)
            return (1);
        else 
        {
            uint256 z = x;
            for (uint256 i=1; i < y; i++)
                z = mul(z,x);
            return (z);
        }
    }
}

contract Settings {
    /// percent decimal
    uint256 internal decimalPercent = 10000;
    /// percent of pot
    uint256 internal percentBigwin = 5000;
    uint256 internal percentShare = 4500;
    uint256 internal percentNextround = 300;
    uint256 internal percentCost = 200;
    
    
    // percent of share everytime
    uint256 internal percentShareOnetime = 2000;
    
    // percent of bigwinPot
    uint256[3] internal scaleBigwin = [6000, 3000, 1000];
    
    // percent of Extend
    uint256 internal percentExtendMain = 9000;
    uint256 internal percentExtendUpper = 800;
    uint256 internal percentExtendUpperUpper = 200;
    
    modifier isHuman() {
        address _addr = msg.sender;
        uint256 _codeLength;
        
        assembly {_codeLength := extcodesize(_addr)}
        require(_codeLength == 0, "sorry humans only");
        _;
    }
    
    
    modifier validValue (uint256 _val) {
        require(_val >= 1000000000, "pocket lint: not a valid currency");
        require(_val <= msg.value, "not valid value");
        _;
    }
    
    function isContract(address addr) public view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
    
    
}


contract BleedFomo is Ownable, Settings{
    
    using SafeMath for uint256;
    
    event onUserBuy(address _useraddr, uint256 _nkeys);
    
    // key setting
    uint256 private keyPriceInit = 0.01 ether;
    uint256 private percentKeyPriceIncrease = 800;
    uint256 private conditionKeyPriceIncrease = 50;
    uint256 private conditionKeyPriceAttenuation = 4;
    uint256 private decimalKey = 8;
    
    // time setting
    uint256 private checkOutinterval =  5 hours;  
    uint256 private endTimeSettingInit = 1 days;
    uint256 private endTimeSettingMax = 30 minutes;
    uint256 private endTimeSettingMin = 10 minutes;
    uint256 private endTimeSettingIncrease1 = 1 minutes;
    uint256 private endTimeSettingIncrease2 = 20 minutes;
    uint256 private nextroundInterval = 2 hours;   // from gameend to gamestart
    uint256 private timeKeyPriceIncrease = 10 minutes;
    
    // pot value
    uint256 private bigwinPot = 0;
    uint256 private sharePot = 0;
    uint256 private sharePot_next = 0;
    uint256 private nextroundPot = 0;
    uint256 private costPot = 0;
    
    
    uint256 private keyPrice = 0;
    
    uint256 private allKeyNum = 0;
    uint256 private allKeyNum_next = 0;

    
    /// timestamp
    uint256 private startTime = 0;
    uint256 private lastWinnerTime = 0;
    uint256 private endTime = 0;
    
    /// 
    uint256 private checkoutTime = 0;
    
    
    
    uint256 private currentlevelKeycount = 0;
    uint256 private timeKeyLevepUp = 0;   // on what time key leve up
    uint256 private sharenumEveryKey = 0;
    
    uint256 private sharePotUnTreate = 0;  // 20% of sharePot
    uint256 private checkoutCurr = 0;
    
    
    
    address private costaddr = 0xF455e968930419C306b5bfD136717DCf22F11883;
    
    // last three valid users;
    struct BigWinner{
        address addr;
        uint256 timestamp;
    }
    BigWinner[3] private bigWinner;
    
    
    // how many keys user have
    mapping (address => uint256) private userkeys;
    address[] private useraddrs = new address[](0);
   
    
    // 
    mapping (address => uint256) private userkeys_nextround;
    address[] private useraddrs_nextround = new address[](0);
    
    
    // Extend address
    mapping (address => address) private userextend;
    
    /////////////////////////////////////
    /// views
    /////////////////////////////////////
    function getGameTime() public view returns(uint256, uint256){
        return (startTime, endTime);
    }
    
    function getPots() public view returns(uint256, uint256, uint256, uint256) {
        return (bigwinPot, sharePot+sharePot_next, nextroundPot, costPot);
    }
    
    function getKeyPrice() public view returns(uint256) {
        return keyPrice;
    }
    
    function getNextKeyTime() public view returns (uint256){
        return timeKeyLevepUp;
    }
    
    function getCurLevelKeyNum() public view returns (uint256){
        return currentlevelKeycount;
    }
    
    function getCheckoutTime() public view returns (uint256){
        return checkoutTime;
    }
    
    function getAllKeyNum() public view returns (uint256){
        return allKeyNum + allKeyNum_next;              // * 10000 to client
    }
    
    function getBigWinner() public view returns(address, uint256, address, uint256, address, uint256){
        // @dev no sort
        return (bigWinner[0].addr, bigWinner[0].timestamp, bigWinner[1].addr, bigWinner[1].timestamp, bigWinner[2].addr, bigWinner[2].timestamp);
    }
    
    function getUserKeys(address _useraddr) public view returns(uint256) {
        return userkeys[_useraddr] + userkeys_nextround[_useraddr];   // * 10000 to client
    }
    
    function getExtendAddr(address _useraddr) public view returns(address) {
        return userextend[_useraddr];
    }
    ///
    /////////////////////////////////////
    
    
    // updateKeyPrice
    function _updateKeyPrice(uint256 _nowtime) private returns (uint) {
        if (currentlevelKeycount >= conditionKeyPriceIncrease && _nowtime >= timeKeyLevepUp){
            
            // 
            keyPrice = keyPrice.mul(decimalPercent + percentKeyPriceIncrease) / decimalPercent;
            
            //
            timeKeyLevepUp = _nowtime + timeKeyPriceIncrease;
            
            // Attenuation condition
            if (conditionKeyPriceIncrease <= conditionKeyPriceAttenuation ){
                conditionKeyPriceIncrease = 1;
            }else{
                conditionKeyPriceIncrease = conditionKeyPriceIncrease - conditionKeyPriceAttenuation;
            }
            
            
            currentlevelKeycount = 0;
        }
        return keyPrice;
    }
    
    
    function _calcCheckoutTime(uint256 _now) private {
        uint256 _flagtime = 1537174200;  // GMT+8 2018/9/11/16:00
        if (checkoutTime == 0) {
            checkoutTime = _flagtime;
        }
        while (_now > checkoutTime) {
            checkoutTime = checkoutTime + checkOutinterval;
        }
    }
    
    function _checkoutCost() private {
        if (costPot > 0){
            costaddr.transfer(costPot);
            costPot = 0;
        }
    }
    
    function extendCost(uint256 _val) payable public validValue(_val) {
        costPot.add(_val);
            // TODO
    }
    
    /// when this Round Over, Ready to next Round
    function _newGame(uint256 _starttime) private {
        uint256 i = 0;
        startTime = _starttime;
        _calcCheckoutTime(startTime);
        endTime = startTime + endTimeSettingInit;
        timeKeyLevepUp = _starttime + timeKeyPriceIncrease;
        
        bigwinPot = 0;
        sharePot = 0;
        sharePot_next = 0;
        costPot = 0;
        _setPotValue(nextroundPot, startTime);
        
        keyPrice = keyPriceInit;

        allKeyNum = 0;
        allKeyNum_next = 0;
    
        currentlevelKeycount = 0;
        sharenumEveryKey = 0;
        sharePotUnTreate = 0;  // 20% of sharePot
        checkoutCurr = 0;
        
        // cleanup userdata
        for(i=0; i<useraddrs.length; i++){
            userkeys[useraddrs[i]] = 0;
        }
        useraddrs.length = 0;
        
        for(i=0; i<useraddrs_nextround.length; i++){
            userkeys_nextround[useraddrs_nextround[i]] = 0;
        }
        useraddrs_nextround.length = 0;
        
        for (i=0; i<3; i++){
            bigWinner[i].addr = 0;
            bigWinner[i].timestamp = 0;
        }
    }
    
    /// checkOut sharePot and BigPot.
    /// @return numbers of not execute count
    function CheckOut(uint256 _executeCount) public returns (uint256) {
        uint256 _now = now;
        uint256 executeCount = 100; //default count
        uint256 i=0;
        uint256 j=0;
        uint256 k=0;
        bool overflag = false;
        uint256 tmpv1 = 0;
        uint256 rst = 0;
        
        require(_now >= checkoutTime, "not ready to checkOut");
        
        if(_executeCount > 0 &&  _executeCount < 1000){
            executeCount = _executeCount;
        }

        
        // 1. checkoutcost
        _checkoutCost();
        
        
        // 2. sharePot and bigwinPot
        if (sharePotUnTreate == 0 && allKeyNum > 0){
            if (isActivate(_now)){
                sharePotUnTreate = sharePot.mul(percentShareOnetime) / decimalPercent;
            }else{
                sharePotUnTreate = sharePot;
            }
            
            sharenumEveryKey = sharePotUnTreate.mul(decimalPercent) / allKeyNum;
        }
        
        
        // cheout bigwinPot
        if ( !isActivate(_now) ){
            // 1. sort bigWinner
            BigWinner memory tmpBW = BigWinner(0,0);
            for (i=0; i<3; i++){
                for(j=i; j<3; j++){
                    if (bigWinner[i].timestamp < bigWinner[j].timestamp){
                        tmpBW.addr = bigWinner[i].addr;
                        tmpBW.timestamp = bigWinner[i].timestamp;
                        bigWinner[i].addr = bigWinner[j].addr;
                        bigWinner[i].timestamp = bigWinner[j].timestamp;
                        bigWinner[j].addr = tmpBW.addr;
                        bigWinner[j].timestamp = tmpBW.timestamp;
                    }
                }
            }
            
            // 2. send to bigWinner
            for(i=0; i<3; i++){
                tmpv1= bigwinPot.mul(scaleBigwin[i]) / decimalPercent;
                if (tmpv1 > 0){
                    bigWinner[i].addr.transfer(tmpv1);
                }
            }
            // over flag
            overflag = true;
        }
        
        
        // checout sharePot;
        if (sharePotUnTreate > 0){
            for (i=0; i<executeCount; i++){
                
                if (checkoutCurr >= useraddrs.length) {
                    
                    // checkout all over
                    checkoutCurr = 0;
                    allKeyNum = allKeyNum.add(allKeyNum_next);
                    allKeyNum_next = 0;
                    sharePot = sharePot.add(sharePot_next);
                    sharePot_next = 0;
                    sharePotUnTreate = 0;
                    
                    for(k=0; k<useraddrs_nextround.length; k++){
                        address _tmpaddr_next = useraddrs_nextround[k];
                        userkeys[_tmpaddr_next].add(userkeys_nextround[_tmpaddr_next]);
                        userkeys_nextround[_tmpaddr_next] = 0;
                    }
                    useraddrs_nextround.length = 0;
                    
                    _calcCheckoutTime(_now);
                    
                    break;
                }else{
                    
                    address  uaddr = useraddrs[checkoutCurr];
                    tmpv1 = userkeys[uaddr].mul(sharenumEveryKey) / decimalPercent;
                    if (tmpv1 > 0){
                        uaddr.transfer(tmpv1);
                        sharePot = sharePot.sub(tmpv1);
                    }
                    
                    checkoutCurr = checkoutCurr.add(1);
                }
            }
        }
        
        if(checkoutCurr == 0){
            rst = 0;
        }else{
            rst = useraddrs.length.sub(checkoutCurr);
        }
        
        
        // cleanup all
        if(overflag){
            _newGame(_now + nextroundInterval);
        }
        
        return rst;
    }
    
    
    
    ///
    function _setPotValue(uint256 _value, uint256 _now) private {
        if (_now > checkoutTime){
            sharePot_next = sharePot_next.add(_value.mul(percentShare) / decimalPercent);
        }else{
            sharePot = sharePot.add(_value.mul(percentShare) / decimalPercent);
        }
        
        bigwinPot = bigwinPot.add(_value.mul(percentBigwin) /  decimalPercent);
        nextroundPot = nextroundPot.add(_value.mul(percentNextround) /  decimalPercent);
        costPot = costPot.add(_value.mul(percentCost) /  decimalPercent);
    }
    
    /// 
    function _setUserInfo(address _useraddr, uint256 _nkeys, uint256 _now, address _upper) private {
        if (_now > checkoutTime){
            // 1. if no checkOut set to userkeys_nextround
            if (userkeys_nextround[_useraddr] == 0) {
                useraddrs_nextround.push(_useraddr);
            }
            userkeys_nextround[_useraddr] = userkeys_nextround[_useraddr].add(_nkeys);
        }else{   
            // 2. set to userkeys;
            if (userkeys[_useraddr] == 0) {
                useraddrs.push(_useraddr);
            }
            userkeys[_useraddr] = userkeys[_useraddr].add(_nkeys);
        }
        
        
        // extend info to save
        if (userextend[_useraddr] == 0){
            // create extendaddr
            if (_upper == 0){
                userextend[_useraddr] = new Extend(_useraddr, this, 0);
            }else{
                userextend[_useraddr] = new Extend(_useraddr, this, userextend[_upper]);
            }
        }
        
    }
    
    function _setAllKeys(uint256 _nkeys, uint256 _now) private {
        
        currentlevelKeycount = currentlevelKeycount.add(_nkeys / decimalPercent);
        
        // 1. if no checkOut add to allKeyNum_next
        if (_now < checkoutTime){
            allKeyNum = allKeyNum.add(_nkeys);   // *10000 to save
        }else{
            // 2. add to allKeyNum_next
            allKeyNum_next = allKeyNum_next.add(_nkeys);
        }
    }
    
    
    
    function _calcEndTime(uint256 _now) private {
        uint256 timediff = endTime - _now;
        
        if ( timediff >= endTimeSettingMax){
            return;  // no change;
        }else if(timediff < endTimeSettingMax && timediff >= endTimeSettingMin){
            endTime = _now + endTimeSettingIncrease1;
        }else if(timediff < endTimeSettingMin ){
            endTime = _now + endTimeSettingIncrease2;
        }
    }
    
    ///
    function _setBigWinner (address _useraddr, uint256 _nkeys, uint256 _now) private {
        uint256 intKeys = _nkeys / decimalPercent;
        if (intKeys < 1){
            return;  // so litte keys to hit BigPot
        }
        
        lastWinnerTime = _now;
        
        if(intKeys >=3){
            for (uint i=0; i<3; i++){
                bigWinner[i].addr = _useraddr;
                bigWinner[i].timestamp = _now;
            }
        }else if(intKeys == 2){ // 2 or 1 intKeys
            uint256 tmpstamp = 0;
            uint256 curr = 99;
            
            // find last winner
            for (uint n=0; n<3; n++){
               if(bigWinner[n].timestamp >= tmpstamp){
                   tmpstamp = bigWinner[n].timestamp;
                   curr = n;
               }
            }
            
            // cover others 2 winner
            if (curr == 99){  // No old bigWinner
                bigWinner[0].addr = _useraddr;
                bigWinner[0].timestamp = _now;                
                bigWinner[1].addr = _useraddr;
                bigWinner[2].timestamp = _now;    
            }else{
                for (uint k=0; k<3; k++){
                    if(curr != k){
                        bigWinner[k].addr = _useraddr;
                        bigWinner[k].timestamp = _now;
                    }
                }
            }
            
        }else if(intKeys == 1){
            uint256 tmpstamp2 = 999999999999;
            uint256 curr2 = 99;
            
            // find 3nd winner, cover it
            for (uint j=0; j<3; j++){
               if(bigWinner[j].timestamp < tmpstamp2){
                   tmpstamp2 = bigWinner[j].timestamp;
                   curr2 = j;
               }
            }
            
            if(curr2 == 99){
                bigWinner[0].addr = _useraddr;
                bigWinner[0].timestamp = _now;   
            }else{
                bigWinner[curr2].addr = _useraddr;
                bigWinner[curr2].timestamp = _now;  
            }
        }
        
        // reset end time
        _calcEndTime(_now);
    }
    
    function isActivate(uint256 _now) public view returns (bool) {
        return (_now > startTime && _now < endTime);
    }
    
    
    // validValue(_val)
    function joinGame(address _sender, uint256 _val, address _upper)  payable validValue(_val) public {
        
        uint256 nowtime = now;
        
        require(isActivate(nowtime), "error game not open");
        
        uint256 realval = 0;
        uint256 costadd = 0;
        
        // 1. veriy valid eth
        if(_upper == 0){
            // no upper, 10% to costPot
            realval = _val.mul(percentExtendMain) / decimalPercent;
            costadd = _val.sub(realval);
        }else{
            realval = _val;
        }
        
        uint256 nkeys = realval.mul(decimalPercent) / (keyPrice.mul(percentExtendMain) / decimalPercent);   // *10000 to save
        require(nkeys >= 6000, "to litte eth");   // num of keys must > 0.6
        
        // 2. calc how many keys user have
        _setUserInfo(_sender, nkeys, nowtime, _upper);
        
        // 3. count  all keys
        _setAllKeys(nkeys, nowtime);
        
        // 4. updateKeyPrice
        _updateKeyPrice(nowtime);
        
        // 5. set pot value
        _setPotValue(realval, nowtime);
        costPot = costPot.add(costadd);
        
        // 6. set bigWinner
        _setBigWinner(_sender, nkeys, nowtime);
        
        //trig event
        emit onUserBuy(_sender, nkeys);
    }
    
    
    
    /// @dev player join this game
    function() payable public validValue (msg.value){
        if(isContract(msg.sender)){
            return;
        }
        joinGame(msg.sender, msg.value, 0);
    }
    
    constructor() public{
        
        //init
        _newGame(now);

    }
}

contract Extend is Settings{
    
    using SafeMath for uint256;
    
    address private extender = 0;   // person address
    
    // contract address
    address private con_main = 0;
    address private con_upper = 0;  
    
    constructor(address _extender, address _con_main, address _con_upper) public {
        extender = _extender;
        con_main = _con_main;
        con_upper = _con_upper;
    }
    
    function transferExtender(uint256 _val) public validValue(_val) {
        extender.transfer(_val);
    }
    
    function getExtender() public view returns(address) {
        return extender;
    }
    
    function() payable public {
        _joinGame(msg.sender, msg.value.mul(percentExtendMain) / decimalPercent);
        _share(msg.value.mul(percentExtendUpper + percentExtendUpperUpper) / decimalPercent );
    }
    
    
    function _share(uint256 _val) private validValue(_val) {
        
        uint256 sharecurrent = _val.mul(percentExtendUpper) / (percentExtendUpper + percentExtendUpperUpper);
        uint256 shareupper = _val.mul(percentExtendUpperUpper) / (percentExtendUpper + percentExtendUpperUpper);
        
        // 8% to extender, 2% to upper
        extender.transfer(sharecurrent);
        
        if (con_upper == 0){
            // no upper 
            BleedFomo bf = BleedFomo(con_main);
            bf.extendCost.value(shareupper)(shareupper);
        }else{
            Extend ex = Extend(con_upper);
            address upaddr = ex.getExtender(); 
            upaddr.transfer(shareupper);
        }
    }
    
    function _joinGame(address _sender, uint256 _val) private {
        //
        BleedFomo bf = BleedFomo(con_main);
        
        bf.joinGame.value(_val)(_sender, _val, extender);
    }
    
}