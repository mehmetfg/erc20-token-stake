//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import  "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import  "@openzeppelin/contracts/security/Pausable.sol";
import  "@openzeppelin/contracts/access/Ownable.sol";
import  "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import  "@openzeppelin/contracts/utils/math/SafeMath.sol";
import  "@openzeppelin/contracts/security/ReentrancyGuard.sol";

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
 *
 */


contract Staking is Pausable,Ownable, ReentrancyGuard{

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

    Investor investor;

    mapping(address => InvestorStorage)  investments;

    IERC20 public stakingToken;

    address  public  tokenOwner;
    uint256 public rateScale = 10000;


    event Staked(address account, uint amount, uint time, uint percent);
    event Withdraw(address account, uint amount, uint time, uint percent);

    /* ========== CONSTRUCTOR ========== */
    constructor(IERC20 _token, address _tokenOwner) {
        stakingToken = _token; // token contract address
        tokenOwner = _tokenOwner; // owner account to withdraw token
    }

    /* ========== modifier ======== */
    modifier validDestination(address _to){
        require(_to != address(0x0));
        require(_to != address(stakingToken));
        _;
    }

    /* ========== internals ======== */
    function transferToContract(uint amount) internal {
        uint _allowance = stakingToken.allowance(tokenOwner, address(this));
        require(amount <= _allowance, "insufficient allowance");
        stakingToken.safeTransferFrom(tokenOwner, address(this), amount);
    }

    // to calculate the rewards by  rate
    function calculateTotalAmount(uint amount, uint rate)  public view   returns(uint){
        return amount.add(amount.mul(rate).div(rateScale));
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    // the authorized user tokenowner draws the balance from the account to the contract and makes the stake to the relevant account.
    function stake(address  account, uint amount, uint day, uint rate) public  whenNotPaused onlyOwner validDestination(account){
        require(amount > 0, "can not stake 0");
        // require(day > 0, "can not day 0");
        require(investments[account].investors.length <= 5 ,"array length can be up to 5");

        uint _time      = block.timestamp.add(day.mul(1 days));
        uint _amount    = calculateTotalAmount(amount, rate);

        transferToContract(_amount);

        //virtual balance is created with the stake reward
        investor.balance    = _amount;
        investor.time       = _time;
        investments[account].investors.push(investor);
        investments[account].totalUserBalance += _amount;

        emit Staked(account, amount, _time, rate);
    }


    // withdraw staked amount if possible
    function withdraw(uint index) public whenNotPaused nonReentrant{

        require(investments[_msgSender()].investors.length > 0, "array is empty");


        investor = investments[_msgSender()].investors[index];

        require(investor.balance > 0, "balance must be greater than 0");
        require(investor.time < block.timestamp, "time has not expired");


        remove(_msgSender(), index);

        //virtual balance is withdraw to the account
        stakingToken.safeTransfer(_msgSender(), investor.balance);

        emit Withdraw(_msgSender(), investor.balance, index, block.timestamp);
    }

    //as a result of withdrawing the balance, the virtual balance is removed
    function remove(address account, uint index) internal {
        uint  _length =investments[account].investors.length;

        if(_length > 1){
            investments[account].investors[index] = investments[account].investors[_length-1];
            investments[account].totalUserBalance -= investments[account].investors[index].balance;
            investments[account].investors.pop();
        } else {
            investments[account].totalUserBalance -= investments[account].investors[index].balance;
            investments[account].investors.pop();
        }
    }

    /* =========== views ==========*/

    function getInvestorInfo(address account) external view
    returns(
        uint[] memory balances,
        uint[] memory times
    ){
        uint _lenght = investments[account].investors.length;
        uint[] memory _balances = new uint[](_lenght);
        uint[] memory _times= new uint[](_lenght);
        for(uint i = 0; i < _lenght; i++){
            _balances[i] = investments[account].investors[i].balance;
            _times[i]  =   investments[account].investors[i].time;
        }
        return (_balances, _times);
    }

    // stakingToken amount in the contract
    function contractBalanceOf() external view returns(uint){
        return stakingToken.balanceOf(address(this));
    }

    // the virtual balance is shown along with the stake total amount
    function balanceOf(address account) external view returns(uint){
        return investments[account].totalUserBalance;
    }

}