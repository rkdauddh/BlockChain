//SPDX-License-Identifier: SNU
pragma solidity ^0.8.0;

//need to import an ERC20 open source.

contract manage {
    address private owner;
    event TransferOwnership(address oldown, address newown);
    function Owned() internal virtual{
        owner = msg.sender;
    }

    modifier Owneroper(){
        require(msg.sender == owner, "ERROR: Only Manager can operate this function.");
        _;
    }

    function transferOwnership(address _new) internal virtual Owneroper(){
        address oldown = owner;
        owner = _new;

        emit TransferOwnership(oldown, owner);

    }

}

contract Beneficiary is manage {//for beneficiary
    address private beneficiary;
    uint idx;//counter

    struct ContributionList {
        uint status_; // 1:open, 2:close / string으로 하면 modifier에서 string memory로 instance를 선언해야 하는데, 그러면 compare가 안됨..
        address beneficiaryAddress_;
        uint256 startDate_; 
        uint256 closedDate_;
    }

    ContributionList [] public status;

    struct Contribution {
        uint256 _Amount; //기부액
        uint256 _date; //기부날짜
        string _contributor; //기부자 이름을 기부자가 정해서 넣을 수 있도록?
    }

    function Addcontribution(address _beneficiary, uint _status, uint256 sdate, uint256 cdate) internal virtual Beneoper(){
        status[idx++] = ContributionList(_status,_beneficiary,sdate,cdate);
    }

    modifier Beneoper(){
        require(msg.sender == beneficiary, "ERROR:Only Beneficiary can operate this function.");
        _;
    }

    function IsBene(address add) internal virtual returns(bool){
        return (add==beneficiary);
    }


    function CheckandClose(uint256 date) internal virtual Owneroper() {
        //각 기부의 status가 유효한지 확인하고, 날짜 지난 기부는 close로 만든다. (관리자만 할 수 있는 기능)
        //어차피 관리자가 open을 할 경우는 없으니까(close된 기부를 open하는 대신 새로운 기부를 만들면 되니까) 닫기만 한다.
        for(uint i=0; i<idx; i++){
            require(status[i].status_ == 1 || status[i].status_ == 2, "ERROR : invalid status"); //수정필요 : 어느 인덱스의 상태가 invalid한지(int를 string으로 바꾸는 함수가 따로 없어 구현 필요)
            if(status[i].closedDate_<=date&&status[i].status_ == 1){
                status[i].status_ = 2;
            }
        }
    }
}

contract Donator is manage, Beneficiary{
    address public donator;
    struct donation{
        uint256 _date;
        uint256 _amount;
    }
    mapping(address => donation[]) public Totaldonation;

    modifier donaoper(){
        require(msg.sender == donator, "ERROR:Only Donator can operate this function");
        _;
    }

    function updateDonation(address _donator, uint256 _amount) internal virtual donaoper(){
        Totaldonation[_donator].push(donation(block.timestamp,_amount));
    }


}

contract Cointribution is Beneficiary, Donator/*, ERC20 */{
//다음주까지 완료 예정
    string private _name;
    string private _symbol;
    uint8 private _decimals = 2;
    uint256 private _totalsupply;
    uint256 private _price;
    
    function name() public view virtual returns (string memory){
        return _name;
    }
    
    function symbol() public view virtual returns (string memory){
        return _symbol;
    }
    
    modifier isvalid(address beneficiary_, uint contributionidx){
        require(IsBene(beneficiary_), "ERROR: You can donate to only beneficiaries");
        require(status[contributionidx].beneficiaryAddress_ == beneficiary_, "ERROR: Wrong beneficiary address");
        require(status[contributionidx].status_ == 1, "ERROR: The contribution is closed");
        _;
    }

    mapping (address => uint256) private _balances;

    mapping(address => Contribution[]) private beneHistory;

    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }

    constructor(string memory name_, string memory symbol_, uint256 totalsupply_, uint256 price_) Beneoper(){
        _name = name_;
        _symbol = symbol_;
        _totalsupply = totalsupply_;
        _price = price_;
    }

    function donate(address _beneficiary, uint index, uint256 _value , string memory doname) internal virtual isvalid(_beneficiary, index){
        //특정 수혜자의 index번째 기부(토큰 판매)에 _value만큼의 토큰을 구매함으로써 참여 
        //수혜자가 기부자에게 토큰을 파는 형태. 토큰을 사는 행위 = 기부 ; 이더 지불 구현은 skip
        require(_value > 0, "ERROR: cannot donate 0 tokens");
        require(balanceOf(_beneficiary)>=_value, "ERROR: Not enough token");

        _balances[msg.sender] += _value;
        _balances[_beneficiary] -= _value;
        updateDonation(msg.sender,_value*_price); //토큰 수 * 토큰 가격만큼 이더를 지불한 셈 치고 기부자 장부에 기록
        beneHistory[_beneficiary].push(Contribution(_value,block.timestamp,doname)); // 판매한 토큰, 구매자 주소를 수혜자 장부에 기록
        
        emit Transfer(_beneficiary, donator, _value);
    }

    function _mint(uint256 amount) internal virtual Beneoper(){
        //수혜자가 판매용 토큰 받기(수혜자만 가능)
        emit Transfer(address(0), msg.sender, amount);
    }

    function _burn(uint256 amount) internal virtual Beneoper(){
        //판매하고 남은 Token 소각
        require(balanceOf(msg.sender) >= amount, "ERROR: not enough token");
        
        emit Transfer(msg.sender, address(0), amount);
    }



    function withdrawal() internal virtual{
        //토큰을 인출하여 거래소에서 거래하는 등 활동을 할 수 있다. -> 토큰 구매 행위 = 기부
        //수혜자가 토큰을 인출하여 판매할 시 - 구매자가 기부자가 되는 것.
        //기부자가 토큰을 인출하여 판매할 시 - 기부자가 구매자에게 기부를 양도하는 것(최종 기부자 = 구매자 / 기부액 = 최초 기부자가 지불한 금액(고정))
        //구현은 안하고 개념적으로만 언급하면 어떨지..ㅎㅎ
    }

    event Transfer(address indexed from, address indexed to, uint256 value); // 수혜자가 기부자에게 토큰을 보내는 event
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