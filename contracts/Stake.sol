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


contract Stake is Pausable,Ownable{

    using SafeERC20 for IERC20;
    using SafeMath for uint;
    struct Investor {
        uint balance;
        uint time;
    }

    struct InvestorStorage {
        uint  totalUserBalance;
        Investor[] investors;
    }

    mapping(address => InvestorStorage)  investments;
    IERC20 public token;
    address  public  tokenOwner;
    uint256 public rateScale = 10000;
    event Deposite(address account, uint amount, uint time, uint percent);
    event Withdraw(address account, uint amount, uint time, uint percent);

    constructor(IERC20 _token, address _tokenOwner) {
        token = _token;
        tokenOwner = _tokenOwner;
    }

    modifier validDestination(address _to){
        require(_to != address(0x0));
        require(_to != address(token));
        _;
    }

    function _transferToContract(address tokenOwner , uint amount) internal {
        uint _allowance = token.allowance(account, address(this));
        require(amount > _allowance, "insufficient allowance");
        token.safeTransferFrom(account, address(this), _amount);
    }


    function deposite(address  account, uint amount, uint day, uint rate) public  onlyOwner validDestination(account){
        require(amount > 0, "can not stake 0");
        // require(day > 0, "can not day 0");
        require(rate < 200, "must be a multiple of 10");
        require(investments[account].investors.length <= 5 ,"array length can be up to 5");

        uint _time      = block.timestamp.add(day.mul(1 days));
        uint _percent   = rate.div(10);
        uint _amount= amount.add(amount.mul(rate).div(rateScale)));

        _transferToContract(tokenOwner, _balance);

        Investor.balance    = _balance;
        Investor.time       = _time;
        investments[account].investors.push(Investor);
        investments[account].totalUserBalance += _balance;

        emit Deposite(account, amount, _time, _percent);
    }

    /**
    * @dev withdraw stake balance
   */
    function withdraw(address account, uint index) public whenNotPaused  validDestination(account){
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

        if(investments[account].investors.length > 1){
            investments[account].investors[index] = investments[account].investors[arrayLength-1];
            investments[account].totalUserBalance -= investments[account].investors[index].balance;
            investments[account].investors.pop();
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



    function balanceERC20(address account) public view returns(uint){
        return token.balanceOf(account);
    }


    function balanceOf(address account) public view returns(uint){
        return investments[account].totalUserBalance;
    }
}