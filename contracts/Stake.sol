//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
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



interface IERC20 {

    function decimals() external view returns(uint256);

    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}



/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */


abstract contract Context{

    function _msgSender() internal virtual view returns(address){
        return msg.sender;
    }


    function _msgData() internal virtual view returns(bytes memory){
        return msg.data;
    }

}
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }


    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;


    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
   */
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
   */
    modifier whenPaused() {
        require(paused);
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
   */
    function pause() onlyOwner whenNotPaused public {
        paused = true;
        emit Pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
   */
    function unpause() onlyOwner whenPaused public {
        paused = false;
        emit Unpause();
    }
}

contract Stake is Pausable{

    struct Investor {
        uint balance;
        uint time;
        uint percent;
    }

    struct InvestorStorage {
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

        require(
            token.transferFrom(account, address(this), _amount),
                "transfer not worked");
        deposite(account, _amount, day, percent);
    }

    function approve(address spender, uint amount) public {
        token.approve(spender, amount);
    }

    function deposite(address  account, uint amount, uint day, uint percent) public  onlyOwner validDestination(account){

        require(amount > 0, "can not stake 0");
        // require(day > 0, "can not day 0");
        require(percent % 10 == 0 && percent < 200, "must be a multiple of 10");
        Investor memory _investor;
        uint _time      = block.timestamp + day * 1 days;
        uint _percent   = percent / 10;
        require(contractERC20Balance() >= _totalLockedBalance + amount + amount / 10 * _percent, "insufficient balance");
        _investor.balance    = amount;
        _investor.time       = _time;
        _investor.percent    = _percent;
        investments[account].investors.push(_investor);
        _totalLockedBalance += amount + amount / 10 * _percent;
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

        token.transfer(account, _amount);
        emit Withdraw(account, _amount, index, block.timestamp);
    }

    function remove(address account, uint index) internal {

        uint arrayLength =  investments[account].investors.length;

        if(arrayLength > 1){
            investments[account].investors[index] = investments[account].investors[arrayLength-1];
            investments[account].investors.pop();
            _totalLockedBalance -= investments[account].investors[index].balance;
        } else {
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
        token.transfer(_msgSender(), totalBalance);
        return true;
    }

    function contractERC20Balance() public view returns(uint){
        uint _balance = token.balanceOf(address(this));
        return _balance;
    }

    function removeInvestList(address account, uint index) public {
        remove(account, index);
    }

    function balanceERC20(address account) public view returns(uint){
        return token.balanceOf(account);
    }

    function totalLockedBalance() public view returns(uint){
        return _totalLockedBalance;
    }

    function balanceOf(address _account) public view returns(uint){
        uint _balance;
        for(uint i = 0; i < investments[_account].investors.length; i++)
        {
            _balance += investments[_account].investors[i].balance +
            investments[_account].investors[i].balance / 10 *
            investments[_account].investors[i].percent ;
        }
        return _balance;
    }
}