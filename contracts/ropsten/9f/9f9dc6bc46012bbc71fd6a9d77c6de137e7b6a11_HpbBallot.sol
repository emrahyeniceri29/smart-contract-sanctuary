pragma solidity ^0.4.24;

contract HpbBallot {
    
    uint256 constant public MAX_UINT256 = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    function safeAdd(uint256 x, uint256 y) internal pure returns (uint256 z){
        if (x > MAX_UINT256 - y) {
            revert();
        }
        return x + y;
    }

    function safeSub(uint256 x, uint256 y) internal pure returns (uint256 z){
        if (x < y){
            revert();
        }
        return x - y;
    }

    function safeMul(uint256 x, uint256 y) internal pure returns (uint256 z){
        if (y == 0){
            return 0;
        }
        if (x > MAX_UINT256 / y) {
            revert();
        }
        return x * y;
    }
    
    
    // 票池名称
    // pool name
    string public name = "HpbBallot-2018-09-20";
    
    // 开始投票的区块号
    // startBlock specifies from which block our vote starts.
    uint public startBlock = 0;
    
    // 结束投票的区块号
    // endBlock specifies from which block our vote ends.
    uint public endBlock = 0;
    
    // 当前票池的版本号
    // currrent pool version
    uint public version = 1;
    
    // 候选者的结构体
    // Candidate struct
    struct Candidate{
        
        // 候选人账户地址
        // Candidate account address
        address candidateAddr;
        
        // 候选人名称
        // Name of candidate
        string name;
        
        // 候选者机器id(编号或者节点)
        // Candidate machine ID (node ID)
        string facilityId;
        
        // 得票数
        // Number of votes
        uint numberOfVotes;
        
        //对候选者投票的投票者数组，用于遍历用途
        //An array of voters for the candidates to be used for traversal.
        address[] voterMapAddrs;
        
        // 已经投票了投票人账户地址-》投票数
        // The voting address of voters has been voted
        mapping (address => uint) voterMap;
        
    }
    
    // 投票结构体
    // Voting structure
    struct Voter{
        
        //投票人的账户地址
        //Address of voters
        address voterAddr;
        
        //快照余额
        //Snapshot balance
        uint snapshotBalance;
        
        //投票人已经投票数(实际投票数)
        //Voters have voted number.
        uint voteNumber;
        
        //用于遍历投票了的候选者用途
        //Candidate use for traversing voting
        address[] candidateMapAddrs;
        
        // 已经投票了的候选者账户地址-》投票数
        // The candidate&#39;s account address has been voted
        mapping (address => uint) candidateMap;
        
    }
    
    struct VoteStage{
        
        uint blockNumber;
        
        // 候选者的数组
	    // An array of candidates
	    Candidate[] candidateArray;
	    
	    /*
	     * 候选者的地址与以上变量候选者数组（candidateArray）索引(数组下标)对应关系,用于查询候选者用途
	     * 这样可以降低每次遍历对象对gas的消耗，存储空间申请和申请次数远远小于查询次数，并且计票步骤更加复杂，相比较消耗gas更多
	     * The address of the candidate corresponds to the index (array subscript) of 
	     * the candidate array of variables above for the purpose of querying candidates
	     * This reduces the consumption of gas for each traversal object, reduces the number of requests and requests for 
	     * storage space far less than the number of queries,and makes the counting step more complex than consuming gas.
	    */
	    mapping (address => uint) candidateIndexMap;
	    
	    //投票者数组
	    // An array of voters
	    Voter[] voterArray;
	    
	    // 投票者的地址与投票者序号（voterArray下标）对应关系，便于查询和减少gas消耗
	    // The voter&#39;s address corresponds to the voter&#39;s ordinal number (voter Array subscript), making it easy to query and reduce gas consumption
	    mapping (address => uint) voterIndexMap;
        
    }
    //分阶段投票
    VoteStage[] public voteStages;
    mapping (uint => uint) voteStageIndexMap;
    uint public voteStageBlock;
    
    //最终获选者总数（容量，获选者数量上限）
    //the total number of final winners (capacity, the upper limit of the number of candidates selected)
    uint public capacity;
    
    // 增加候选者
    // add candidate
    event CandidateAdded(address indexed candidateAddr,string indexed facilityId,string name);
    
    // 更新候选者
    // update candidate
    event CandidateUpdated(address indexed candidateAddr,string indexed facilityId,string name);
    
    // 删除候选者
    // delete candidate
    event CandidateDeleted(address indexed candidateAddr);
    
    // 投票
    // vote
    event DoVoted(address indexed voteAddr,address indexed candidateAddr,uint num,uint flag);
    
    // 改变投票区间值,改变保证金最少金额,改变投票版本号
    // Change the voting interval and change the voting number.
    event ChangeOfBlocks(uint indexed version,uint startBlock, uint endBlock,uint capacity);
    
    event ChangeStageBlcok(uint indexed stageBlcok);

    // 记录发送HPB的发送者地址和发送的金额
    // Record the sender address and the amount sent to send HPB.
    event ReceivedHpb(address indexed sender, uint amount);

	//接受HPB转账
	//Accept HPB transfer
    function () payable  external{
       emit ReceivedHpb(msg.sender, msg.value);
    }
   //对投票者设置快照余额的管理员
   //Administrators who set up snapshot balances for voters
   mapping (address => address) public adminMap;
   
   //必须是快照管理员才能设置快照余额
   //The snapshot administrator must set the snapshot balance.
   modifier onlyAdmin{
        require(adminMap[msg.sender] != 0);
        _;
   }
   
   //增加设置快照余额的管理员
   //Add administrator to set snapshot balance
   function addAdmin(address addr) onlyOwner  public{
        adminMap[addr] = addr;
   }
   
   address public owner;
    
   /**
    * 只有HPB基金会账户（管理员）可以调用
    * Only the HPB foundation account (administrator) can call.
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
     * Constructor function
     * 构造函数 初始化投票智能合约的部分依赖参数
     */
    constructor(
        //开始投票的区块号
    	// `startBlock` specifies from which block our vote starts.
        uint _startBlock,
         
        //结束投票的区块号
        // `endBlock` specifies from which block our vote ends.
        uint _endBlock,
        //获选者总量
        //the total number of final winners
        uint _capacity,
         
        //当前票池的版本号
        //currrent pool version
        uint _version
     ) payable public{
            require(_startBlock< _endBlock);
         	owner = msg.sender;
	        startBlock= _startBlock;
	        endBlock= _endBlock;
	        capacity=_capacity;
	        version=_version;
	        
	        //设置默认管理员
	        adminMap[owner]=owner;
	        
			//设置默认的阶段block
			voteStageBlock=_startBlock;
	        voteStages.length++;
	        voteStageIndexMap[voteStageBlock]=0;
	        uint voteStageIndex=voteStageIndexMap[voteStageBlock];
	        
	        //设置第一位置
	        //Set the first position.
	        voteStages[voteStageIndex].blockNumber=voteStageBlock;
	        voteStages[voteStageIndex].voterIndexMap[msg.sender]=0;
            voteStages[voteStageIndex].voterArray.push(Voter(msg.sender,0,0,new address[](0)));
            
            voteStages[voteStageIndex].candidateIndexMap[msg.sender]=0;
	        voteStages[voteStageIndex].candidateArray.push(Candidate(msg.sender,&#39;0&#39;,&#39;0&#39;,0,new address[](0)));
            
	        emit ChangeOfBlocks(_version,startBlock,_endBlock,_capacity);
     }

 	function changeStageBlcok(
        uint _voteStageBlock
    ) onlyOwner public{
        require(voteStageBlock< _voteStageBlock);
        uint voteStageIndex=voteStageIndexMap[voteStageBlock];
        voteStageBlock=_voteStageBlock;
        voteStages.length++;
	    voteStageIndex=voteStageIndex+1;
	    voteStageIndexMap[voteStageBlock]=voteStageIndex;
	    
        //设置第一位置
        //Set the first position.
        voteStages[voteStageIndex].blockNumber=voteStageBlock;
        voteStages[voteStageIndex].voterIndexMap[msg.sender]=0;
        voteStages[voteStageIndex].voterArray.push(Voter(msg.sender,0,0,new address[](0)));
        
        voteStages[voteStageIndex].candidateIndexMap[msg.sender]=0;
        voteStages[voteStageIndex].candidateArray.push(Candidate(msg.sender,&#39;0&#39;,&#39;0&#39;,0,new address[](0)));
        emit ChangeStageBlcok(_voteStageBlock);
    }
   /**
     * 管理员修改投票智能合约的部分依赖参数
     * Administrators modify some dependent parameters of voting smart contracts.
     */
    function changeVotingBlocks(
        uint _startBlock,
        uint _endBlock,
        uint _capacity,
        uint _version
    ) onlyOwner public{
        require(_startBlock< _endBlock);
        startBlock = _startBlock;
        endBlock = _endBlock;
        capacity = _capacity;
        version = _version;
        emit ChangeOfBlocks(_version,_startBlock, _endBlock,_capacity);
    }
    
    /**
     * 管理员启动投票开始
     */
    function beginVote() onlyOwner public{
        startBlock = block.number;
    }
    /**
     * 管理员启动投票结束
     * The administrator starts the voting.
     */
    function endVote() onlyOwner public{
        endBlock = block.number;
    }
    /**
     * 只有投票开始后执行
     * Only after voting begins.
     */
    modifier onlyVoteAfterStart{
        require(block.number>= startBlock);
        _;
    }
    /**
     * 只有投票进行中执行
     * Only voting is carried out.
     */
    modifier onlyVoteInProgress{
        require(block.number>= startBlock);
        require(block.number<= endBlock);
        _;
    }

    /**
     * 只有投票结束前执行
     * Only before voting is finished
     */
    modifier onlyVoteBeforeEnd{
        require(block.number<= endBlock);
        _;
    }

    /**
     * 只有投票结束后执行
     * Only after voting is finished
     */
    modifier onlyVoteAfterEnd{
        require(block.number> endBlock);
        _;
    }

    /**
     *增加候选者  add Candidate 
     * 
     * @param _candidateAddr Candidate account address for return bond (HPB)
     * @param _facilityId 候选者机器设备号或者节点ID Candidate machine equipment number or node ID
     * @param _name 候选者名称  Candidate name
     * 
     */
    function addCandidate(
        address _candidateAddr,
        string _facilityId,
        string _name
    ) onlyOwner onlyVoteBeforeEnd public{
        uint voteStageIndex=voteStageIndexMap[voteStageBlock];
        uint index = voteStages[voteStageIndex].candidateIndexMap[_candidateAddr];
        // 判断候选人是否已经存在 Judge whether candidates exist.
        if (index == 0) { // 如果没有，就添加  If not, add
            index = voteStages[voteStageIndex].candidateArray.length;
            voteStages[voteStageIndex].candidateIndexMap[_candidateAddr]=index;
	        voteStages[voteStageIndex].candidateArray.push(Candidate(_candidateAddr,_name,_facilityId,0,new address[](0)));
	        emit CandidateAdded(_candidateAddr,_facilityId,_name);
        }
    }
    /**
     * 更新候选者 update Candidate 
     * @param _candidateAddr Candidate account address for return bond (HPB)
     * @param _facilityId 候选者机器设备号或者节点ID Candidate machine equipment number or node ID
     * @param _name 候选者名称  Candidate name
     * 
     */
    function updateCandidate(
        address _candidateAddr,
        string _facilityId,
        string _name
    ) onlyOwner onlyVoteBeforeEnd public{
        // 判断候选人是否已经存在 Judge whether candidates exist.
        require(voteStages[voteStageIndex].candidateIndexMap[_candidateAddr] != 0);
        uint voteStageIndex=voteStageIndexMap[voteStageBlock];
        uint index = voteStages[voteStageIndex].candidateIndexMap[_candidateAddr];
        voteStages[voteStageIndex].candidateArray[index].facilityId=_facilityId;
        voteStages[voteStageIndex].candidateArray[index].name=_name;
        emit CandidateUpdated(_candidateAddr,_facilityId,_name);
    }

    /**
     * 删除候选者 Delete Candidate 
     * @param _candidateAddr 候选者账户地址 Candidate account address
     */
    function deleteCandidates(
        address _candidateAddr
    ) onlyOwner onlyVoteBeforeEnd public{
        uint voteStageIndex=voteStageIndexMap[voteStageBlock];
        /**
         * 删除候选者投票 Delete candidate vote
         */
        uint index=voteStages[voteStageIndex].candidateIndexMap[_candidateAddr];
        require(index!= 0);
        for(uint n=0;n<voteStages[voteStageIndex].candidateArray[index].voterMapAddrs.length;n++){
           //得到投票者 get voter
           uint voterIndex = voteStages[voteStageIndex].voterIndexMap[voteStages[voteStageIndex].candidateArray[index].voterMapAddrs[i]];
	       uint cindex=0;
	        for (uint k = 0;k<voteStages[voteStageIndex].voterArray[voterIndex].candidateMapAddrs.length-1;k++){
	            if(voteStages[voteStageIndex].voterArray[voterIndex].candidateMapAddrs[k]==_candidateAddr){
	                //得到候选者所处投票者结构体中的位置 Gets the position of the candidate in the structure of the voters.
	                cindex=k;
	            }
	            //如果投票者结构体中候选者存在 If the candidate in the voter structure is exist
	            if(cindex>0&&k>=cindex){
	                voteStages[voteStageIndex].voterArray[voterIndex].candidateMapAddrs[k]=voteStages[voteStageIndex].voterArray[voterIndex].candidateMapAddrs[k+1];
	            }
	        }
	        //撤回已经投的票
	        voteStages[voteStageIndex].voterArray[voterIndex].voteNumber=safeSub(
	            voteStages[voteStageIndex].voterArray[voterIndex].voteNumber,
	            voteStages[voteStageIndex].voterArray[voterIndex].candidateMap[_candidateAddr]
	        );
	        voteStages[voteStageIndex].voterArray[voterIndex].candidateMap[_candidateAddr]=0;
	        
	        delete voteStages[voteStageIndex].voterArray[voterIndex].candidateMapAddrs[voteStages[voteStageIndex].voterArray[voterIndex].candidateMapAddrs.length-1];
	        voteStages[voteStageIndex].voterArray[voterIndex].candidateMapAddrs.length--;
	        	
        }
        
        for (uint i = index;i<voteStages[voteStageIndex].candidateArray.length-1;i++){
            voteStages[voteStageIndex].candidateArray[i] = voteStages[voteStageIndex].candidateArray[i+1];
        }
        delete voteStages[voteStageIndex].candidateArray[voteStages[voteStageIndex].candidateArray.length-1];
        voteStages[voteStageIndex].candidateArray.length--;
        voteStages[voteStageIndex].candidateIndexMap[_candidateAddr]=0;
        emit CandidateDeleted(_candidateAddr);
    }
   
	
	/**
     * 撤回对某个候选人的投票 Withdraw a vote on a candidate.
      */
	function cancelVoteForCandidate(
		address candidateAddr,
    	uint num
    ) onlyVoteInProgress public {
	    address voterAddr = msg.sender;
	    uint voteStageIndex=voteStageIndexMap[voteStageBlock];
        uint index=voteStages[voteStageIndex].voterIndexMap[voterAddr];
        //必须投过票 Tickets must be cast.
        require(index!=0);
        uint candidateIndex=voteStages[voteStageIndex].candidateIndexMap[candidateAddr];
        //候选人必须存在 Candidates must exist
        require(candidateIndex!=0);
        //必须已投候选者票数大于取消数量
        uint cnum=voteStages[voteStageIndex].voterArray[index].candidateMap[candidateAddr];
        require(cnum>=num);
        
        voteStages[voteStageIndex].candidateArray[candidateIndex].voterMap[voterAddr]=safeSub(voteStages[voteStageIndex].candidateArray[candidateIndex].voterMap[voterAddr],num);
        voteStages[voteStageIndex].candidateArray[candidateIndex].numberOfVotes=safeSub(voteStages[voteStageIndex].candidateArray[candidateIndex].numberOfVotes,num);
        
        voteStages[voteStageIndex].voterArray[index].candidateMap[candidateAddr]=safeSub(cnum,num);
        
        voteStages[voteStageIndex].voterArray[index].voteNumber=safeSub(voteStages[voteStageIndex].voterArray[index].voteNumber,num);
        
        //todo
        emit DoVoted(voterAddr,candidateAddr,num,0);
	}

    /**
     * 设置投票人的快照余额（以指定的区块号为准，到时候由官方或者HPB基金会对外公布）
     * Set the voter&#39;s snapshot balance (subject to the designated block number, 
     * to be published by the official or HPB Foundation)
      */
    function  voteSnapshotBalance(
    	address voterAddr,
    	uint _snapshotBalance
    )onlyAdmin onlyVoteInProgress public {
        require(_snapshotBalance>0);
        uint voteStageIndex=voteStageIndexMap[voteStageBlock];
        uint index=voteStages[voteStageIndex].voterIndexMap[voterAddr];
        if (index == 0) { // 如果从没投过票，就添加投票人 If you never cast a vote, you add voters.
            index =voteStages[voteStageIndex].voterArray.length;
            voteStages[voteStageIndex].voterIndexMap[voterAddr] =index;
            voteStages[voteStageIndex].voterArray.push(Voter(voterAddr,_snapshotBalance,0,new address[](0)));
        }else{
            voteStages[voteStageIndex].voterArray[index].snapshotBalance=_snapshotBalance;
        }
    }
    
 	/**
     * 用于非质押(锁定)投票  For non locked voting
      */
    function  voteNoLock(
    	address candidateAddr,
    	uint num
    ) onlyVoteInProgress public {
        // 获取投票人的账户地址 Get the address of the voters.
        address voterAddr = msg.sender;
        uint voteStageIndex=voteStageIndexMap[voteStageBlock];
        uint index=voteStages[voteStageIndex].voterIndexMap[voterAddr];
        require(index != 0);
        //剩余的可投票数必须大于投票数
        require(safeSub(voteStages[voteStageIndex].voterArray[index].snapshotBalance,voteStages[voteStageIndex].voterArray[index].voteNumber)>=num);
        doVote(candidateAddr,index,num);
    }
    /**
     * 执行投票 do vote
      */
    function doVote(
        address candidateAddr,
        uint index,
    	uint num
    ) onlyVoteInProgress internal {
        require(num>0);
        uint voteStageIndex=voteStageIndexMap[voteStageBlock];
        uint candidateIndex=voteStages[voteStageIndex].candidateIndexMap[candidateAddr];
        //候选人必须存在 Candidates must exist
        require(candidateIndex!=0);
        
        bool hasVoterAddr=false;
        for (uint i = 1;i<voteStages[voteStageIndex].candidateArray[candidateIndex].voterMapAddrs.length;i++){
            if(voteStages[voteStageIndex].voterArray[index].voterAddr==voteStages[voteStageIndex].candidateArray[candidateIndex].voterMapAddrs[i]){
                hasVoterAddr=true;
                break;
            }
	    }
	    if(!hasVoterAddr){
	        voteStages[voteStageIndex].candidateArray[candidateIndex].voterMapAddrs.push(voteStages[voteStageIndex].voterArray[index].voterAddr);
	        //uint vl=voteStages[voteStageIndex].candidateArray[candidateIndex].voterMapAddrs.length;
	        //voteStages[voteStageIndex].candidateArray[candidateIndex].voterMapAddrs.length=safeAdd(vl,1);
	        //voteStages[voteStageIndex].candidateArray[candidateIndex].voterMapAddrs[vl]=voterAddr;
	    }
        
        // 获取候选人中的投票人信息，并重新记录投票数 Get the information of voters in the candidate and re record the number of votes.
       
        voteStages[voteStageIndex].candidateArray[candidateIndex].voterMap[voteStages[voteStageIndex].voterArray[index].voterAddr]=
        safeAdd(voteStages[voteStageIndex].candidateArray[candidateIndex].voterMap[voteStages[voteStageIndex].voterArray[index].voterAddr],num);
	    
        //投票人已投总数累加
        voteStages[voteStageIndex].voterArray[index].voteNumber=safeAdd(voteStages[voteStageIndex].voterArray[index].voteNumber,num);
        
        bool hasAddr=false;
        for (uint k = 1;k<voteStages[voteStageIndex].voterArray[index].candidateMapAddrs.length;k++){
            if(candidateAddr== voteStages[voteStageIndex].voterArray[index].candidateMapAddrs[k]){
                hasAddr=true;
                break;
            }
	    }
	    if(!hasAddr){
	        voteStages[voteStageIndex].voterArray[index].candidateMapAddrs.push(candidateAddr);
	        //uint l=voteStages[voteStageIndex].voterArray[index].candidateMapAddrs.length;
	        //voteStages[voteStageIndex].voterArray[index].candidateMapAddrs.length=safeAdd(l,1);
	        //voteStages[voteStageIndex].voterArray[index].candidateMapAddrs[l]=candidateAddr;
	    }
	    
	    //候选者得票数累加
        voteStages[voteStageIndex].candidateArray[candidateIndex].numberOfVotes=safeAdd(voteStages[voteStageIndex].candidateArray[candidateIndex].numberOfVotes,num);
        uint candidateNum=voteStages[voteStageIndex].voterArray[index].candidateMap[candidateAddr];
        voteStages[voteStageIndex].voterArray[index].candidateMap[candidateAddr]=safeAdd(candidateNum,num);
        
        emit DoVoted(voteStages[voteStageIndex].voterArray[index].voterAddr,candidateAddr,num,1);
    }   
   
    /**
     * 得到即时投票结果 Get instant results.
      */
    function voteCurrentResult(
    ) onlyVoteAfterStart public constant returns(
        address[] addr,
        bytes32[] facilityIds,
        uint[] nums
    ){ 
        return calResult();
    }
    
    function stringToBytes32(string memory source) internal pure returns (bytes32 result) {
       assembly {
        result := mload(add(source, 32))
      }
    }
    
    /**
     * 获取所有候选人的详细信息
     * Get detailed information about all candidates.
      */
    function fechAllCandidates(
    ) onlyVoteAfterStart public constant returns (
        address[] addrs,
        bytes32[] names,
        bytes32[] facilityIds
    ){
        uint voteStageIndex=voteStageIndexMap[voteStageBlock];
        address[] memory _addrs=new address[](voteStages[voteStageIndex].candidateArray.length);
        bytes32[] memory _names=new bytes32[](voteStages[voteStageIndex].candidateArray.length);
        bytes32[] memory _facilityIds=new bytes32[](voteStages[voteStageIndex].candidateArray.length);
        for(uint i=0;i<voteStages[voteStageIndex].candidateArray.length;i++){
            _addrs[i]=voteStages[voteStageIndex].candidateArray[i].candidateAddr;
            _names[i-1]=stringToBytes32(voteStages[voteStageIndex].candidateArray[i].name);
            _facilityIds[i-1]=stringToBytes32(voteStages[voteStageIndex].candidateArray[i].facilityId);
        }
        return (_addrs,_names,_facilityIds);
    }
    /**
     * 选举并计票，获取投票结果
     * Vote and count the votes.
      */
    function calResult(
    ) onlyVoteAfterStart internal constant returns(
        address[] addr,
        bytes32[] facilityIds,
        uint[] nums
    ){ 
         
         address[] memory _addrs=new address[](capacity);
         bytes32[] memory _facilityIds=new bytes32[](capacity);
         uint[] memory _nums=new uint[](capacity);
         uint voteStageIndex=voteStageIndexMap[voteStageBlock];
         uint min=voteStages[voteStageIndex].candidateArray[1].numberOfVotes;
         uint minIndex=0;
         for (uint i = 1;i<voteStages[voteStageIndex].candidateArray.length;i++){
             if(i<=capacity){
                 //先初始化获选者数量池 Initialize the number of pools selected first.
                 _addrs[i-1]=voteStages[voteStageIndex].candidateArray[i].candidateAddr;
                 _facilityIds[i-1]=stringToBytes32(voteStages[voteStageIndex].candidateArray[i].facilityId);
                 _nums[i-1]=voteStages[voteStageIndex].candidateArray[i].numberOfVotes;
                 //先记录获选者数量池中得票最少的记录 Record the number of votes selected in the pool.
                 if(_nums[i-1]<min){
                     min=_nums[i-1];
                     minIndex=i-1;
                 }
             }else{
               if(voteStages[voteStageIndex].candidateArray[i].numberOfVotes==min){
                   //对于得票相同的，取持币数量多的为当选 For the same votes, the number of holding currencies is high.
                   /**
                    * if(voteStages[voteStageIndex].candidateArray[i].candidateAddr.balance>_addrs[minIndex].balance){
                       _addrs[minIndex]=voteStages[voteStageIndex].candidateArray[i].candidateAddr;
		               _facilityIds[minIndex]=stringToBytes32(voteStages[voteStageIndex].candidateArray[i].facilityId);
		               _nums[minIndex]=voteStages[voteStageIndex].candidateArray[i].numberOfVotes;
                   }
                   * 
                   */
               }else if(voteStages[voteStageIndex].candidateArray[i].numberOfVotes>min){
              	   _addrs[minIndex]=voteStages[voteStageIndex].candidateArray[i].candidateAddr;
	               _facilityIds[minIndex]=stringToBytes32(voteStages[voteStageIndex].candidateArray[i].facilityId);
	               _nums[minIndex]=voteStages[voteStageIndex].candidateArray[i].numberOfVotes;
	               
	               //重新记下最小得票者 Recount the smallest ticket winner
	               for(uint k=0;k<_addrs.length;k++){
	                   if(_nums[k]<min){
		                     min=_nums[k];
		                     minIndex=k;
		               }
	               }
	               min=_nums[minIndex];
               }
             }
        }
        return (_addrs,_facilityIds,_nums);
    }
    
    /**
     * 得到最终投票结果 Get the final vote.
      */
    function voteResult(
    ) onlyVoteAfterEnd public constant returns(
        address[] addr,
        bytes32[] facilityIds,
        uint[] nums
    ){
        return calResult();
    }
    
    
    /**
     * 获取投票人的快照余额和总投票数
     * Get the snapshot balances and total votes of voters.
      */
    function fechVoteMainInfo(
    ) onlyVoteAfterStart public constant returns (
        uint snapshotBalance,
        uint voteNumber
    ){
        uint voteStageIndex=voteStageIndexMap[voteStageBlock];
        uint index = voteStages[voteStageIndex].voterIndexMap[msg.sender];
        if(index==0){//没投过票 No vote
        	return (0,0);
        }
        return (
            voteStages[voteStageIndex].voterArray[index].snapshotBalance,
            voteStages[voteStageIndex].voterArray[index].voteNumber
        );
    }
    
    /**
     * 获取投票人的所有投票情况 Get all the votes of voters.
     */
    function fechVoteInfoForVoter(
        address voterAddr,
        uint _voteStageBlock
    ) onlyVoteAfterStart public constant returns (
        address[] addrs,
        uint[] nums
    ){
        uint voteStageIndex=voteStageIndexMap[_voteStageBlock];
        uint index = voteStages[voteStageIndex].voterIndexMap[voterAddr];
        if(index==0){//没投过票 No vote
        	return (new address[](0),new uint[](0));
        }
        
        uint[] memory _nums=new uint[](voteStages[voteStageIndex].voterArray[index].candidateMapAddrs.length);
        for(uint i = 1;i<voteStages[voteStageIndex].voterArray[index].candidateMapAddrs.length;i++){
            _nums[i]=voteStages[voteStageIndex].voterArray[index].candidateMap[voteStages[voteStageIndex].voterArray[index].candidateMapAddrs[i]];
        }
        return (voteStages[voteStageIndex].voterArray[index].candidateMapAddrs,_nums);
    }
    
    /**
     * 获取所有候选人的投票情况
     * Obtain the votes of all candidates.
     */
    function fechAllForCandidate(
        uint _voteStageBlock
    ) onlyVoteAfterStart public constant returns (
        address[] addr,
        uint[] nums
    ){
        uint voteStageIndex=voteStageIndexMap[_voteStageBlock];
        address[] memory _addrs=new address[](voteStages[voteStageIndex].candidateArray.length);
        uint[] memory _nums=new uint[](voteStages[voteStageIndex].candidateArray.length);
        for(uint i=0;i<voteStages[voteStageIndex].candidateArray.length;i++){
            _addrs[i]=voteStages[voteStageIndex].candidateArray[i].candidateAddr;
            _nums[i]=voteStages[voteStageIndex].candidateArray[i].numberOfVotes;
        }
        return (_addrs,_nums);
    }
    
    /**
     * 获取候选人的总得票数
     * Total number of votes obtained from candidates
     */
    function fechVoteNumForCandidate(
        address candidateAddr,
        uint _voteStageBlock
    ) onlyVoteAfterStart public constant returns (
        uint num
    ){
        uint voteStageIndex=voteStageIndexMap[_voteStageBlock];
        uint index = voteStages[voteStageIndex].candidateIndexMap[candidateAddr];
        require(index>0);
        return voteStages[voteStageIndex].candidateArray[index].numberOfVotes;
    }
    
    /**
     * 获取候选人的竞选详细情况  Obtain details of candidates&#39; campaign.
     */
    function fechVoteResultForCandidate(
       address candidateAddr,
       uint _voteStageBlock
    ) onlyVoteAfterStart internal constant returns (
        address[] addr,
        uint[] nums
    ){
        uint voteStageIndex=voteStageIndexMap[_voteStageBlock];
        uint index = voteStages[voteStageIndex].candidateIndexMap[candidateAddr];
        require(index>0);
        // 如果候选人存在,即时更新竞选情况 If candidates exist, update the campaign immediately.
        uint[] memory _nums=new uint[](voteStages[voteStageIndex].candidateArray[index].voterMapAddrs.length);
        for(uint i=0;i<voteStages[voteStageIndex].candidateArray[index].voterMapAddrs.length;i++){
            _nums[i]=voteStages[voteStageIndex].candidateArray[index].voterMap[voteStages[voteStageIndex].candidateArray[index].voterMapAddrs[i]];
        }
        return (voteStages[voteStageIndex].candidateArray[index].voterMapAddrs,_nums);
    }
}