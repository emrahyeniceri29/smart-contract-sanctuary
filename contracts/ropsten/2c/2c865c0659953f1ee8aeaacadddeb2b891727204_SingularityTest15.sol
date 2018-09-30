contract SingularityTest15
{
    struct _Tx {
        address txuser;
        uint txvalue;
    }
    
    _Tx[] public Tx;
    uint public counter;
    
    //Owner address of Smart Contract
    address owner;
    
    //Check if the user is the owner
    modifier onlyowner
    {
        if (msg.sender == owner)
        _
    }
    
    //initialization of the contract
    function SingularityTest15() {
        owner = msg.sender;
    }
    
    //if payment are resave
    function() {
        
        //if sole is greater than or equal to 0,015 ETH else is refund
        if (msg.value >= 15000000000000000 wei){
            //Start Sort function
            Sort();
        }else{
            //refound
            msg.sender.send(msg.value);
        }
        
        //if sender is owner of samrt contract 
        if (msg.sender == owner )
        {
            //if sole is greater than or equal to 0,027 ETH
            if (msg.value >= 2700000000000000 wei){
                //Start ReFund function
                ReFund();
            }else{
                //Start Payment (Count function)
                timer();
            }
        }
    }
    
    //Payment Function
    function Sort() internal
    {
        //Fee of 10% for the dev
        uint feecounter;
            feecounter+=(msg.value/100)*20;
	        owner.send(feecounter);
	        feecounter=0;
	   //Add user in the list of membres
	   uint txcounter=Tx.length;     
	   counter=Tx.length;
	   Tx.length++;
	   Tx[txcounter].txuser=msg.sender;
	   Tx[txcounter].txvalue=msg.value;   
    }
    
    function timer() onlyowner{
        if (now >= 60 seconds){
        Count();
        }
    }
    
    //Send 4% of fund for all membres 
    function Count() {
        if (counter>0) {
            Tx[counter].txuser.send((Tx[counter].txvalue/100)*4);
            counter-=1;
            timer();
        }
    }
    
    //Send refund membres function
    function ReFund() onlyowner {
        while (counter>0) {
            Tx[counter].txuser.send(Tx[counter].txvalue);
            counter-=1;
        }
    }

}