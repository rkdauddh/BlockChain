// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract ERC20 {
    mapping (uint => string) private _coinName;             // key: 기부리스트의 index,    value: 코인명
    mapping (uint => string) private _coinSymbol;           // key: 기부리스트의 index,    value: 코인심볼
    mapping (uint => uint256) private _totalSupply;         // key: 기부리스트의 index,    value: 코인총발행량
    mapping (address => uint256) private _balances; // key: 기부리스트의 index,    value: 코인잔량         //코인잔량은, 기부자들이 기부하는 금액만큼 차감된다.
   
    function _createCoinbutor(uint _index, string memory _name, string memory _symbol, uint256 _amount, address _donationFundingAddress) internal returns (bool) {
        _coinName[_index] = _name;
        _coinSymbol[_index] = _symbol;
        _totalSupply[_index] = _amount;
        _balances[_donationFundingAddress] = _amount;        //기부리스트 생성 초기에, 수혜자주소에 발행한 ERC20코인 총량을 넣는다. 이후 기부자들이 이를 구매시 차감된다.

        emit Transfer(address(0), _donationFundingAddress, _amount);
        return true;
    }
   
    function transfer(address donatorAddr, address beneficiaryAddr, uint256 amount) public virtual returns (bool) {
        _transfer(donatorAddr, beneficiaryAddr, amount);
        return true;
    }


    // 기부자는 ETHER로 수혜자가 발행한 코인을 사는 방식으로 기부를 하는 형태임.
    // 기부자의 ETHER잔액을 읽어와 차감하는 부분에 대한 구현은 생략함.
    // 기부자가 수혜자의 ERC20 코인을 얻는 방식만 구현하였음
    function _transfer( address _donatorAddr, address _beneficiaryAddr, uint256 _amount) internal virtual {
        require(_donatorAddr != address(0), "ERC20: transfer from the zero address");
        require(_beneficiaryAddr != address(0), "ERC20: transfer to the zero address");

        uint256 ableBalance = _balances[_beneficiaryAddr];
        require(ableBalance >= _amount, "ERC20: amount exceeds donation able amount");
        _balances[_beneficiaryAddr] = ableBalance - _amount;            // 수혜자의 잔액에서 기부금액만큼 차감 처리
        _balances[_donatorAddr] = _balances[_donatorAddr] + _amount;    // 기부자의 잔액에서 기부금액만큼 증감 처리
       
        //기부자의 ETHER잔액을 읽어와 차감하는 부분에 대한 구현은 생략함.

   //     emit _transfer(_donationListIndex, _donatorAddr, _beneficiaryAddr, _amount);
    }  
   
    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }

    event Transfer(address indexed from, address indexed to, uint256 value);
}


contract DonationAGroup is ERC20{ /* ERC20을 상속받는다.*/
    // (구조체1) 기부리스트
    struct DonationList {
        string title;               // 기부제목
        uint status;              // 기부상태 1:open, 2:close - 1이면 open, 2면 close
        string contents;            // 기부모집내용
        uint256 startDate;           // 기부시작일
        uint256 closedDate;          // 기부종료일
        string coinName;
        string coinSymbol;    
        address donationFundingAddress; // 기부모집계좌
        uint256 donationFundingAmount; // 기부모집금액

    }
   
    // (구조체2) 기부거래내역
    struct DonationTransaction {
        uint donationListIndex; // 기부리스트의 인덱스
        address donatorAddress; // 기부자주소
        uint256 donatorAmount;  // 기부금액
        uint256 donationDate;     // 기부일자
    }
   
    mapping (uint => address) public donationListIndexToBeneficary;  // key: 기부리스트의 index,    value: 수혜자주소
    mapping (address => uint) public beneficiaryToDonationListIndex; // key:수혜자주소,             value: 기부리스트의 index
    mapping (address => uint256) public donatedBalance;              // key:수혜자주소,             value: 기부된금액
    mapping (address => uint) public donatedCount;                   // key:수혜자주소,             value: 기부참여자수
   
    uint donationListIndex; // 기부리스트 counter
   
 //   mapping (address => uint) beneficaryto;
 
    DonationList[] public donationLists;
    DonationTransaction[] public donationTransactions;
   
    constructor() {
        donationListIndex = 0;
    }


    // (function 1) 수혜자가 화면에서 기부목록 등록시 호출한다.
    // 1. _donationFundingAmount만큼 ERC20을 생성한다.
    // 2. donationLists에 입력받은 기부목록정보를 insert한다.
    // 3.기부된 금액 초기화
    // 4.기부 참여자수 초기화
    function addContributionList(string memory _title,
                                  string memory _contents,
                                  uint256 _startDate,
                                  uint256 _term,
                                  string memory _coinName,
                                  string memory _coinSymbol,
                                  uint256 _donationFundingAmount) public {
                                     
        uint _status;
        if(_startDate>block.timestamp){
            _status =2;
        }
        else{
            _status =1;
        }

        bool result = _createCoinbutor(donationListIndex, _coinName, _coinSymbol, _donationFundingAmount, msg.sender);  // 1. _donationFundingAmount만큼 ERC20을 생성한다.                      

        require(result, "ERROR:cannot create token");
        _addContributionList( _title, _status, _contents, _startDate, _startDate+_term, _coinName, _coinSymbol, msg.sender, _donationFundingAmount); // 2. donationLists에 입력받은 기부목록정보를 insert한다.                                
        donatedBalance[msg.sender] = 0;// 3.기부된 금액 초기화
        donatedCount[msg.sender] = 0;  // 4.기부 참여자수 초기화

    }
   
    // (function 1 related)
    function _addContributionList(string memory _title,
                                  uint _status,
                                  string memory _contents,
                                  uint256 _startDate,
                                  uint256 _closedDate,
                                  string memory _coinName,
                                  string memory _coinSymbol,
                                  address _donationFundingAddress,
                                  uint256 _donationFundingAmount) internal {
        donationLists.push(DonationList( _title, _status, _contents, _startDate, _closedDate, _coinName, _coinSymbol, _donationFundingAddress, _donationFundingAmount));  //DonationList에 값을 push한다.
        donationListIndexToBeneficary[donationListIndex] = _donationFundingAddress;
        beneficiaryToDonationListIndex[_donationFundingAddress] = donationListIndex++;
        donatedCount[_donationFundingAddress] = 0;
    }
   
    // (function 2) 기부자가 기부화면에 들어오면 기부리스트를 가져와 보여준다.
    // (requestType) 1: 전체리스트, 2: open상태인 리스트 전체, 3: close상태인 리스트 전체.. 로 하려다가 2번 구현시 에러나서 일단 스킵..;
    function getDonationList(uint _requestType) public view returns (DonationList[] memory){
        uint idx=0;
        DonationList[] memory openDonationList;
       
        if(_requestType == 1){
            for(uint i=0; i<= donationListIndex; i++){
                    openDonationList[idx++] = donationLists[i];
            }
        }
        else if(_requestType == 2){
            for(uint i=0; i<= donationListIndex; i++){
                if(donationLists[i].status == 1){
                    openDonationList[idx++] = donationLists[i];
                }
            }
        }
            return openDonationList;
    }
   
    // (function 3) 기부자가 리스트 중 선택해서 기부금액 입력하고 submit버튼 클릭시 호출된다.
    // 1. transfer() 함수를 통해 기부자는 수혜자가 발행한 ERC20 coin을 구매한다.
    // 2.
    function Donation(address _beneficiaryAddr, uint256 _amount) public {
        uint idx = beneficiaryToDonationListIndex[_beneficiaryAddr];
        transfer(msg.sender, _beneficiaryAddr, _amount);
        _afterTransaction(idx, msg.sender, _beneficiaryAddr, _amount, block.timestamp); //마지막인자 : 시스템 날짜 어떻게 가져오는지 모름;;
       
    }
   
    function _afterTransaction(uint _donationListIndex, address _donatorAddress, address _beneficiaryAddr, uint256 _donatorAmount, uint256 _donationDate) internal {
        donationTransactions.push(DonationTransaction( _donationListIndex, _donatorAddress, _donatorAmount, _donationDate));  //donationTransactions List에 값을 push한다.
        donatedBalance[_beneficiaryAddr] = donatedBalance[_beneficiaryAddr] + _donatorAmount;
        donatedCount[_beneficiaryAddr]++;
    }


}