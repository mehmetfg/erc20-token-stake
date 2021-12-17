//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

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

contract StakeOld is Pausable, Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    struct Investor {
        uint256 balance;
        uint256 time;
        uint256 percent;
    }

    struct InvestorStorage {
        uint256 totalUserBalance;
        Investor[] investors;
    }

    mapping(address => InvestorStorage) investments;
    IERC20 public token;
    uint256 private _totalLockedBalance;

    event Deposite(
        address account,
        uint256 amount,
        uint256 time,
        uint256 percent
    );
    event Withdraw(
        address account,
        uint256 amount,
        uint256 time,
        uint256 percent
    );

    constructor(IERC20 _token) {
        token = _token;
    }

    modifier validDestination(address _to) {
        require(_to != address(0x0));
        require(_to != address(token));
        _;
    }

    function transferFrom(
        address account,
        uint256 day,
        uint256 percent
    ) public onlyOwner {
        uint256 _amount = token.allowance(account, address(this));
        require(_amount > 0, "allowance 0");
        token.safeTransferFrom(account, address(this), _amount);
        deposite(account, _amount, day, percent);
    }

    function approve(address spender, uint256 amount) public {
        token.safeApprove(spender, amount);
    }

    function deposite(
        address account,
        uint256 amount,
        uint256 day,
        uint256 percent
    ) public onlyOwner validDestination(account) {
        require(amount > 0, "can not stake 0");
        // require(day > 0, "can not day 0");
        require(
            percent.mod(10) == 0 && percent < 200,
            "must be a multiple of 10"
        );
        require(
            investments[account].investors.length <= 5,
            "array length can be up to 5"
        );
        Investor memory _investor;
        uint256 _time = block.timestamp.add(day.mul(1 days));
        uint256 _percent = percent.div(10);
        uint256 _totalUserBalance = amount.add(amount.div(10).mul(_percent));
        require(
            contractERC20Balance() >=
                _totalLockedBalance.add(_totalUserBalance),
            "insufficient balance"
        );
        _investor.balance = amount;
        _investor.time = _time;
        _investor.percent = _percent;
        investments[account].investors.push(_investor);
        investments[account].totalUserBalance += _totalUserBalance;
        _totalLockedBalance += _totalUserBalance;
        emit Deposite(account, amount, _time, _percent);
    }

    /**
     * @dev withdraw stake balance
     */
    function withdraw(address account, uint256 index)
        public
        whenNotPaused
        validDestination(account)
    {
        require(account != address(0x0));
        Investor memory _investor;
        _investor = investments[account].investors[index];
        uint256 arrayLength = investments[account].investors.length;

        require(_investor.balance > 0, "balance must be greater than 0");
        require(arrayLength > 0, "array is empty");
        require(_investor.time < block.timestamp, "time has not expired");

        uint256 _totalPercent = (_investor.balance / 10) * _investor.percent;
        uint256 _amount = _investor.balance + _totalPercent;

        remove(account, index);

        token.safeTransfer(account, _amount);
        emit Withdraw(account, _amount, index, block.timestamp);
    }

    function remove(address account, uint256 index) internal {
        uint256 arrayLength = investments[account].investors.length;

        if (arrayLength > 1) {
            investments[account].investors[index] = investments[account]
                .investors[arrayLength - 1];
            investments[account].totalUserBalance -= investments[account]
                .investors[index]
                .balance;
            investments[account].investors.pop();

            _totalLockedBalance -= investments[account]
                .investors[index]
                .balance;
        } else {
            investments[account].totalUserBalance -= investments[account]
                .investors[index]
                .balance;
            investments[account].investors.pop();
        }
    }

    /**
     * @dev stake investor balance, time, percent information array
     */
    function getInvestorInfo(address account)
        public
        view
        returns (
            uint256[] memory balances,
            uint256[] memory times,
            uint256[] memory percents
        )
    {
        uint256 _lenght = investments[account].investors.length;
        uint256[] memory _balances = new uint256[](_lenght);
        uint256[] memory _times = new uint256[](_lenght);
        uint256[] memory _percents = new uint256[](_lenght);
        for (uint256 i = 0; i < _lenght; i++) {
            _balances[i] = investments[account].investors[i].balance;
            _times[i] = investments[account].investors[i].time;
            _percents[i] = investments[account].investors[i].percent;
        }
        return (_balances, _times, _percents);
    }

    /**
     * @dev withdraw remaining balance
     */
    function withdrawAll() external onlyOwner returns (bool) {
        uint256 totalBalance = token.balanceOf(address(this)) -
            _totalLockedBalance;
        require(totalBalance > 0, "empty");
        token.safeTransfer(_msgSender(), totalBalance);
        return true;
    }

    function contractERC20Balance() public view returns (uint256) {
        uint256 _balance = token.balanceOf(address(this));
        return _balance;
    }

    function balanceERC20(address account) public view returns (uint256) {
        return token.balanceOf(account);
    }

    function totalLockedBalance() public view returns (uint256) {
        return _totalLockedBalance;
    }

    function balanceOf(address account) public view returns (uint256) {
        return investments[account].totalUserBalance;
    }
}
