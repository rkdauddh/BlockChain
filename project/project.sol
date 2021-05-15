//SPDX-License-Identifier: SNU
pragma solidity ^0.8.0;

contract manage {
    address private owner;
    event TransferOwnership(address oldown, address newown);
    function Owned() internal virtual{
        owner = msg.sender;
    }

    function transferOwnership(address _new) internal virtual{
        address oldown = owner;
        owner = _new;

        emit TransferOwnership(oldown, owner);

    }

}

contract Beneficiary is manage {
    address public coin;
    uint idx;//counter
    struct ContributionList {
        uint status_; // 1:open, 2:close / string으로 하면 modifier에서 string memory로 instance를 선언해야 하는데, 그러면 compare가 안됨..
        address beneficiaryAddress_;
        string startDate_; 
        string closedDate_;
    }

    ContributionList [] public status;

    struct Contribution {
        uint256 _Amount; //기부액
        string _date; //기부날짜
        uint256 _index; // 몇 번째 contributor인지
        string _contributor; //기부자 이름을 기부자가 정해서 넣을 수 있도록?
    }
    
    function setStatus(address _beneficiary, uint _status, string memory sdate, string memory cdate) internal virtual{
        status[idx++] = ContributionList(_status,_beneficiary,sdate,cdate);
    }

    function Datetoint(string memory Date) public returns (uint){
        //Date(string)를 int로 바꾸는 함수(closedDate 날짜 지나면 close function으로 닫을 수 있게)
        //구현은 나중에
        return 0;
    }
    function CheckandClose(string memory date) public virtual{
        //각 기부의 status가 유효한지 확인하고, 날짜 지난 기부는 close로 만든다.
        //어차피 관리자가 open을 할 경우는 없으니까(close된 기부를 open하는 대신 새로운 기부를 만들면 되니까) 닫기만 한다.
        for(uint i=0; i<idx; i++){
            require(status[i].status_ == 1 || status[i].status_ == 2, "ERROR : invalid status"); //수정필요 : 어느 인덱스의 상태가 invalid한지(int를 string으로 바꾸는 함수가 따로 없어 구현 필요)
            if(Datetoint(status[i].closedDate_)<=Datetoint(date)&&status[i].status_ == 1){
                status[i].status_ = 2;
            }
        }
    }
}

contract Cointribution is manage {//manage를 상속받아야 할지 beneficiary를 상속받아야 할지 모르겠음.
//다음주까지 완료 예정
}








/*
지난번 코드
contract ERC20 {
    string private _name;
    string private _symbol;
    uint256 private totalsupply;    

    mapping (address => bool) private _isbeneficiary;
    
    //remain tokens
    mapping (address => uint256) private _balances;
    
    //accumulate amount of token donation
    mapping(address => uint256) private _totaldonation;
    
    mapping(address => uint256) private _totaldonator;
    
    mapping(address => mapping(address => uint256)) private _allowances;
    //tokens at first = 21000000
    uint256 private _initialtoken = 21000000;
    
    constructor (string memory name_, string memory symbol_){
        
        _name = name_;
        _symbol = symbol_;
        _isbeneficiary[msg.sender] = true;
        _totaldonator[msg.sender] = 0;
        _balances[msg.sender] = _initialtoken;
        _totaldonation[msg.sender] = 0;

    }
    
    function name() public view virtual returns (string memory){
        return _name;
    }
    
    function symbol() public view virtual returns (string memory){
        return _symbol;
    }
    
    function isbene(address account) public view virtual returns(bool){
        return _isbeneficiary[account];
    }
    function totaldonation(address account) public view virtual returns(uint256){
        return _totaldonation[account];
    }
    
    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }
    function totaldonator(address account) public view virtual returns(uint256){
        require(_isbeneficiary[account] == true, "ERROR:A donator cannot have donator for him(her)self");
        return _totaldonator[account];
    }
    
    function allowance(address beneficiary, address donator) public view virtual returns (uint256){
        return _allowances[beneficiary][donator];
    }
    
    function approve(address donator, uint256 amount) public virtual returns (bool){
        _approve(msg.sender, donator, amount);
        return true;
    }
    
    function donate(address donator, address beneficiary, uint256 amount) internal virtual{
        require(donator !=address(0),"ERROR: transfer from the zero address");
        require(beneficiary !=address(0), "ERROR: transfer to the zero address");
        require(amount>=1, "ERROR: please donate more than minimal unit");
        require(isbene(beneficiary) == true, "ERROR: please donate to beneficiary");
        
        uint256 donatorBalance = _balances[donator];
        require(donatorBalance >= amount, "ERROR: not enough token");
        
        _balances[donator] = donatorBalance - amount;
        _balances[beneficiary] += amount;
        _totaldonation[beneficiary] += amount;
        _totaldonation[donator] += amount; 
        _totaldonator[beneficiary] += 1;
        
        emit Transfer(beneficiary, donator, amount);
        
    }
    
    function buytoken(address donator, uint256 amount) internal virtual{
        require(isbene(donator) != true, "ERROR: beneficiary cannot buy token");
        //buying tokens
    
        emit Transfer(address(0), donator, amount);
    }
    
    function selltoken(address beneficiary, uint256 amount) internal virtual{
        require(isbene(beneficiary) == true, "ERROR: refund is not allowed to donator");
        require(_balances[beneficiary] >= amount, "ERROR: not enough token");
        
        emit Transfer(beneficiary, address(0), amount);
        //sell token and give money to beneficiary
        
    }
    
    function _approve(address beneficiary, address donator, uint256 amount) internal virtual{
        require(_isbeneficiary[beneficiary] == true, "ERROR: cannot approve from donator");
        require(_isbeneficiary[donator]!=true, "ERROR: cannot approve to beneficiary");
        require(donator !=address(0),"ERROR: approve to the zero address");
        require(beneficiary !=address(0), "ERROR: approve from the zero address");
        
        _allowances[beneficiary][donator] = amount;
        emit Approval(beneficiary, donator, amount);
    }
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    }
    */