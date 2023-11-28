// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;
import "./KlayOrarcleInterface.sol";

contract Ownable{
  address  payable public  owner;
  constructor(address payable _owner){
    owner = _owner;
  }

  modifier onlyOwner(){
    require(owner == msg.sender,"not owner");
    _;
}
}

contract InvoiceMatcher is Ownable {


    event Paid(
        uint _invoiceId,
        uint  _timestamp
    );

    event ImvoiceIssued(
        uint _invoiceId,
        address _receiver
    );

    struct Invoice {
        string url;
        address owner;
        address recepient;
        uint usdSum;
        uint klayPrice;
        bool payed;
    }
   
   address public oracleAddress;
   uint public lastReservedInvoice;
   uint8 public tax;
   uint public usersBalance;

   mapping (uint => Invoice) invoices;
   mapping (address => uint) public balances;
   
   constructor(address _oracleAddress, uint8 _tax) Ownable(payable(msg.sender)){
    oracleAddress = _oracleAddress;
    tax = _tax;
   }

    function swap(uint256 _klayOutput) external {
        require(msg.sender == oracleAddress, "not allowed"); 
        Invoice memory thisInvoice = invoices[lastReservedInvoice];
        thisInvoice.klayPrice = _klayOutput;
        invoices[lastReservedInvoice] = thisInvoice;
    }
    // Sum must be 1e9 
    function newInvoce(string memory url, address recepient, uint sum) public returns (uint) {
        //Create new invoice 
        Invoice memory newInvoice = Invoice(
            url,
            msg.sender,
            recepient,
            sum,
            0,
            false
        );
        lastReservedInvoice++;
        invoices[lastReservedInvoice] = newInvoice;
 
        KlayOracleInterface oracle = KlayOracleInterface(oracleAddress);

        oracle.newOracleRequest(
            this.swap.selector,
            address(this)
        );

        emit ImvoiceIssued(lastReservedInvoice, recepient);

        return lastReservedInvoice;
    }

    function pay(uint _invoiceNum) public payable {
         Invoice memory thisInvoice = invoices[_invoiceNum];
         require(thisInvoice.payed == false, "already payed");
         require(thisInvoice.recepient == msg.sender, "not allowed");
         require(calcSum(thisInvoice.usdSum, thisInvoice.klayPrice) == msg.value, "bad sum");
         thisInvoice.payed = true;
         invoices[_invoiceNum] = thisInvoice;
         balances[thisInvoice.owner] += msg.value;
         usersBalance += msg.value;
         emit Paid(_invoiceNum, block.timestamp);
         
     }


     //Returns in wei 
    function calcSum(uint _usdSum, uint _klayPrice) public pure returns(uint){
        uint  _klaySum = _usdSum/_klayPrice;
        return _klaySum * 10**9;        
    }
    function withdrawTax() public onlyOwner() {
        owner.transfer(totalTaxBalance());
    }

    function totalTaxBalance() public view returns(uint) {
        return address(this).balance - usersBalance;
    }

    function withdrawBalance() public {
        require(balances[msg.sender]>0, "nothing to withdraw");
        uint balanceToWithdraw = (balances[msg.sender] * (100 - tax)) / 100;
        payable(msg.sender).transfer(balanceToWithdraw);
        usersBalance -= balances[msg.sender];
        balances[msg.sender] = 0;
    }

    function getInvoiceUrl(uint _invoiceId) public view returns(string memory){
        Invoice memory thisInvoice = invoices[_invoiceId];
        return thisInvoice.url;
    }

    function getInvoiceKlayPrice(uint _invoiceId) public view returns(uint){
        Invoice memory thisInvoice = invoices[_invoiceId];
        return thisInvoice.klayPrice;
    }

     function isPayed(uint _invoiceId) public view returns(bool){
        Invoice memory thisInvoice = invoices[_invoiceId];
        return thisInvoice.payed;
    }

    function isOwner(uint _invoiceId) public view returns(bool){
        Invoice memory thisInvoice = invoices[_invoiceId];
        return thisInvoice.owner == msg.sender;
    }

     function isReceiver(uint _invoiceId) public view returns(bool){
        Invoice memory thisInvoice = invoices[_invoiceId];
        return thisInvoice.recepient == msg.sender;
    }
    
    






}