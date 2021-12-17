/**
 *Submitted for verification at Etherscan.io on 2021-05-15
 */

/**
 *Submitted for verification at Etherscan.io on 2020-09-04
 */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "hardhat/console.sol";

abstract contract IERC20 {
    function totalSupply() public view virtual returns (uint256);

    function balanceOf(address tokenOwner)
        public
        view
        virtual
        returns (uint256);

    function allowance(address tokenOwner, address spender)
        public
        view
        virtual
        returns (uint256);

    function transfer(address to, uint256 tokens) public virtual returns (bool);

    function approve(address spender, uint256 tokens)
        public
        virtual
        returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 tokens
    ) public virtual returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(
        address indexed tokenOwner,
        address indexed spender,
        uint256 tokens
    );
}

contract SafeMath {
    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }
}

contract Token is IERC20, SafeMath {
    string public name;
    string public symbol;
    uint8 public decimals;

    uint256 public _totalSupply;
    address public owner;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    constructor() {
        name = "Mehmet Fatih 0000";
        symbol = "ttt";
        decimals = 6;
        //startDate = block.timestamp +  1 weeks;
        owner = msg.sender;
        _totalSupply = 10000; // * 10 ** decimals;   // 24 decimals
        balances[msg.sender] = _totalSupply;
        // address(uint160(referaddr)).transfer(referamt);
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    /**
     * @dev allowance : Check approved balance
     */
    function allowance(address tokenOwner, address spender)
        public
        view
        virtual
        override
        returns (uint256 remaining)
    {
        return allowed[tokenOwner][spender];
    }

    /**
     * @dev approve : Approve token for spender
     */
    function approve(address spender, uint256 tokens)
        public
        virtual
        override
        returns (bool success)
    {
        require(tokens >= 0, "Invalid value");
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    /**
     * @dev transfer : Transfer token to another etherum address
     */
    function transfer(address to, uint256 tokens)
        public
        virtual
        override
        returns (bool success)
    {
        require(to != address(0), "Null address");
        require(tokens > 0, "Invalid Value");
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    /**
     * @dev transferFrom : Transfer token after approval
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokens
    ) public virtual override returns (bool success) {
        require(to != address(0), "Null address");
        require(from != address(0), "Null address");
        require(tokens > 0, "Invalid value");
        require(tokens <= balances[from], "Insufficient balance");
        require(tokens <= allowed[from][msg.sender], "Insufficient allowance");
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

    /**
     * @dev totalSupply : Display total supply of token
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev balanceOf : Displya token balance of given address
     */
    function balanceOf(address tokenOwner)
        public
        view
        virtual
        override
        returns (uint256 balance)
    {
        return balances[tokenOwner];
    }

    /**
     * @dev mint : To increase total supply of tokens
     */
    function mint(uint256 _amount) public returns (bool) {
        require(_amount >= 0, "Invalid amount");
        require(
            _amount + _totalSupply <= 9000000000 * 10**uint256(decimals),
            "Invalid amount"
        );
        require(owner == msg.sender, "UnAuthorized");
        _totalSupply = safeAdd(_totalSupply, _amount);
        balances[owner] = safeAdd(balances[owner], _amount);
        emit Transfer(address(0), owner, _amount);
        return true;
    }

    /**
     * @dev mint : To increase total supply of tokens
     */
    function burn(uint256 _amount) public returns (bool) {
        require(_amount >= 0, "Invalid amount");
        require(owner == msg.sender, "UnAuthorized");
        require(_amount <= balances[msg.sender], "Insufficient Balance");
        _totalSupply = safeSub(_totalSupply, _amount);
        balances[owner] = safeSub(balances[owner], _amount);
        emit Transfer(owner, address(0), _amount);
        return true;
    }
}
