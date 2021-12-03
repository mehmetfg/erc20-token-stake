//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import  "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import  "@openzeppelin/contracts/security/Pausable.sol";
import  "@openzeppelin/contracts/access/Ownable.sol";
import  "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import  "@openzeppelin/contracts/utils/math/SafeMath.sol";

/*

///       ____ __   __ ____  _____      ____  _____   _     _  __ _____
///      / ___|\ \ / // ___|| ____|    / ___||_   _| / \   | |/ /| ____|
///     | |     \ V /| |    |  _|      \___ \  | |  / _ \  | ' / |  _|
///     | |___   | | | |___ | |___      ___) | | | / ___ \ | . \ | |___
///      \____|  |_|  \____||_____|    |____/  |_|/_/   \_\|_|\_\|_____|

*/
/*
 * @creator: Crypto Carbon Energy
 * @title  : Stake Contract
 * @author : MFG <mehmetfg@gmail.com>
 * @dev
 *
 */


contract StakeOld is Pausable,Ownable{

    using SafeERC20 for IERC20;
    using SafeMath for uint;
    struct Investor {
        uint balance;
        uint time;
        uint percent;
    }

    struct InvestorStorage {
        uint  totalUserBalance;
        Investor[] investors;
    }

    mapping(address => InvestorStorage)  investments;
    IERC20 public token;
    uint   private _totalLockedBalance;

    event Deposite(address account, uint amount, uint time, uint percent);
    event Withdraw(address account, uint amount, uint time, uint percent);

    constructor(IERC20 _token) {
        token = _token;
    }
    modifier validDestination(address _to){
        require(_to != address(0x0));
        require(_to != address(token));
        _;
    }
    function transferFrom(address account,  uint day, uint percent) public onlyOwner{
        uint _amount = token.allowance(account, address(this));
        require(_amount > 0, "allowance 0");
        token.safeTransferFrom(account, address(this), _amount);
        deposite(account, _amount, day, percent);
    }

    function approve(address spender, uint amount) public {
        token.safeApprove(spender, amount);
    }

    function deposite(address  account, uint amount, uint day, uint percent) public  onlyOwner validDestination(account){

        require(amount > 0, "can not stake 0");
        // require(day > 0, "can not day 0");
        require(percent.mod(10) == 0 && percent < 200, "must be a multiple of 10");
        require(investments[account].investors.length <= 5 ,"array length can be up to 5");
        Investor memory _investor;
        uint _time      = block.timestamp.add(day.mul(1 days));
        uint _percent   = percent.div(10);
        uint _totalUserBalance = amount.add(amount.div(10).mul(_percent));
        require(contractERC20Balance() >= _totalLockedBalance.add(_totalUserBalance), "insufficient balance");
        _investor.balance    = amount;
        _investor.time       = _time;
        _investor.percent    = _percent;
        investments[account].investors.push(_investor);
        investments[account].totalUserBalance += _totalUserBalance;
        _totalLockedBalance += _totalUserBalance;
        emit Deposite(account, amount, _time, _percent);
    }

    /**
    * @dev withdraw stake balance
   */
    function withdraw(address account, uint index) public whenNotPaused  validDestination(account){
        require(account != address(0x0));
        Investor memory _investor;
        _investor = investments[account].investors[index];
        uint arrayLength =  investments[account].investors.length;

        require(_investor.balance > 0,
            "balance must be greater than 0");
        require(arrayLength > 0,
            "array is empty");
        require(_investor.time < block.timestamp,
            "time has not expired");

        uint _totalPercent = _investor.balance / 10 * _investor.percent;
        uint _amount = _investor.balance + _totalPercent;

        remove(account, index);

        token.safeTransfer(account, _amount);
        emit Withdraw(account, _amount, index, block.timestamp);
    }

    function remove(address account, uint index) internal {

        uint arrayLength =  investments[account].investors.length;

        if(arrayLength > 1){
            investments[account].investors[index] = investments[account].investors[arrayLength-1];
            investments[account].totalUserBalance -= investments[account].investors[index].balance;
            investments[account].investors.pop();

            _totalLockedBalance -= investments[account].investors[index].balance;
        } else {
            investments[account].totalUserBalance -= investments[account].investors[index].balance;
            investments[account].investors.pop();
        }
    }

    /**
  * @dev stake investor balance, time, percent information array
   */
    function getInvestorInfo(address account) public view
    returns(
        uint[] memory balances,
        uint[] memory times,
        uint[] memory percents
    ){
        uint _lenght = investments[account].investors.length;
        uint[] memory _balances = new uint[](_lenght);
        uint[] memory _times= new uint[](_lenght);
        uint[] memory _percents = new uint[](_lenght);
        for(uint i = 0; i < _lenght; i++){
            _balances[i] = investments[account].investors[i].balance;
            _times[i]  =   investments[account].investors[i].time;
            _percents[i]  = investments[account].investors[i].percent;
        }
        return (_balances, _times, _percents);
    }

    /**
    * @dev withdraw remaining balance
   */
    function withdrawAll() external onlyOwner returns(bool){
        uint totalBalance =  token.balanceOf(address(this)) - _totalLockedBalance;
        require(totalBalance > 0, "empty");
        token.safeTransfer(_msgSender(), totalBalance);
        return true;
    }

    function contractERC20Balance() public view returns(uint){
        uint _balance = token.balanceOf(address(this));
        return _balance;
    }


    function balanceERC20(address account) public view returns(uint){
        return token.balanceOf(account);
    }

    function totalLockedBalance() public view returns(uint){
        return _totalLockedBalance;
    }

    function balanceOf(address account) public view returns(uint){
        return investments[account].totalUserBalance;
    }
}