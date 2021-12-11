//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import  "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import  "@openzeppelin/contracts/security/Pausable.sol";
import  "@openzeppelin/contracts/access/Ownable.sol";
import  "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import  "@openzeppelin/contracts/utils/math/SafeMath.sol";
import  "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "hardhat/console.sol";
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

    struct UserData {
        uint balance;
        uint time;
    }

    struct TimedWithdraw {
        uint  totalUserBalance;
        UserData[] userDataStore;
    }

   //UserData _userData;

    mapping(address => TimedWithdraw)  stakeApplyInfo;

    IERC20 public stakingToken;

    address  public  tokenOwner;
    uint256 public rateScale = 10000;


    event Staked(address account, uint amount, uint time, uint percent);
    event Withdraw(address account, uint amount, uint time, uint percent);

    /* ========== CONSTRUCTOR ========== */
    constructor(IERC20 _token, address _tokenOwner) {
        stakingToken = _token; // contract address of the token to be staked
        tokenOwner = _tokenOwner; // owner account to withdraw the token to be staked
    }

    /* ========== modifier ======== */
    modifier validDestination(address _to){
        require(_to != address(0x0));
        require(_to != address(stakingToken));
        _;
    }

    // to calculate the rewards by  rate
    function calculateTotalAmount(uint amount, uint rate)  internal view   returns(uint){
        return amount.add(amount.mul(rate).div(rateScale));
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    // the authorized user tokenowner draws the balance from the account to the contract and makes the stake to the relevant account.
    function stake(address  account, uint amount, uint day, uint rate) public   onlyOwner whenNotPaused validDestination(account){
        require(amount > 0, "can not stake 0");
        require(day > 0, "can not day 0");
        require(rate <= 30000, "withdraw rate is too high");
        require(stakeApplyInfo[account].userDataStore.length < 5 ,"array length can be up to 5");

        uint _time      = block.timestamp.add(day.mul(1 days));
        uint _amount    = calculateTotalAmount(amount, rate);


       stakingToken.safeTransferFrom(tokenOwner, address(this), _amount);
        UserData memory _userData;
        //virtual balance is created with the stake reward
        _userData.balance    = _amount;
        _userData.time       = _time;
        stakeApplyInfo[account].userDataStore.push(_userData);
        stakeApplyInfo[account].totalUserBalance += _amount;


        emit Staked(account, amount, _time, rate);
    }


    // withdraw staked amount if possible
    function withdraw(uint index) public whenNotPaused nonReentrant{

        require(index < stakeApplyInfo[_msgSender()].userDataStore.length, "index out of bound");
        require(stakeApplyInfo[_msgSender()].userDataStore.length > 0, "array is empty");

        UserData memory _userData;

        _userData = stakeApplyInfo[_msgSender()].userDataStore[index];


        require(_userData.time < block.timestamp, "time has not expired");


        remove(_msgSender(), index);

        //virtual balance is withdraw to the account
        stakingToken.safeTransfer(_msgSender(), _userData.balance);

        emit Withdraw(_msgSender(), _userData.balance, index, block.timestamp);
    }

    //as a result of withdrawing the balance, the virtual balance is removed
    function remove(address account, uint index) internal {
        uint  _length =stakeApplyInfo[account].userDataStore.length;
        if(_length > 1){
            stakeApplyInfo[account].totalUserBalance -= stakeApplyInfo[account].userDataStore[index].balance ;
            stakeApplyInfo[account].userDataStore[index] = stakeApplyInfo[account].userDataStore[_length-1];
            stakeApplyInfo[account].userDataStore.pop();
        } else {
            stakeApplyInfo[account].totalUserBalance = 0;
            stakeApplyInfo[account].userDataStore.pop();
        }
    }

    /* =========== views ==========*/

    function getInvestorInfo(address account) external view
    returns(
        uint[] memory balances,
        uint[] memory times
    ){
        uint _lenght = stakeApplyInfo[account].userDataStore.length;
        uint[] memory _balances = new uint[](_lenght);
        uint[] memory _times= new uint[](_lenght);
        for(uint i = 0; i < _lenght; i++){
            _balances[i] = stakeApplyInfo[account].userDataStore[i].balance;
            _times[i]  =   stakeApplyInfo[account].userDataStore[i].time;
        }
        return (_balances, _times);
    }

    // stakingToken amount in the contract
    function contractBalanceOf() external view returns(uint){

        return stakingToken.balanceOf(address(this));
    }

    // the virtual balance is shown along with the stake total amount
    function balanceOf(address account) external view returns(uint){

        return stakeApplyInfo[account].totalUserBalance;
    }

}