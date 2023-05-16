/**
 *Submitted for verification at BscScan.com on 2022-09-02
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}


interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IFactoryV2 {
    event PairCreated(address indexed token0, address indexed token1, address lpPair, uint);
    function getPair(address tokenA, address tokenB) external view returns (address lpPair);
    function createPair(address tokenA, address tokenB) external returns (address lpPair);
}

interface IV2Pair {
    function factory() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function sync() external;
}

interface IRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function swapExactETHForTokens(
        uint amountOutMin, 
        address[] calldata path, 
        address to, uint deadline
    ) external payable returns (uint[] memory amounts);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IRouter02 is IRouter01 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

contract SPEPE is IERC20 {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping(address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _liquidityHolders;
    
    mapping (address => bool) private _isExcludedFromProtection;
   
    string constant private _name = "SPACE PEPE";
    string constant private _symbol = "SPEPE";
    uint8 constant private _decimals = 6;

    uint256 constant private _totalSupply = 210_000_000_000_000_000 * 10**_decimals;

    uint256 public taxFeeOnBuy = 30;
    uint256 public taxFeeOnSell = 30;

    IRouter02 public dexRouter;

    address public lpPair;
    address public operator;
    address constant public DEAD = 0x000000000000000000000000000000000000dEaD;

    address private _owner;
    address payable private devAddress = payable(0x054428914C1C4703933680AF26e43d1644b94563);

    bool public tradingEnabled = false;
    bool public hasLiqBeenAdded = false;
    bool private allowedPresaleExclusion = true;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(_owner == msg.sender, "Caller =/= owner.");
        _;
    }

    constructor () payable {
        // Set the owner.
        _owner = msg.sender;
        
        _balances[_owner] = _totalSupply;
        emit Transfer(address(0), _owner, _totalSupply);

        if (block.chainid == 56) {
            dexRouter = IRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        } else if (block.chainid == 97) {
            dexRouter = IRouter02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);
        } else if (block.chainid == 1 || block.chainid == 4 || block.chainid == 3) {
            dexRouter = IRouter02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
            //Ropstein DAI 0xaD6D458402F60fD3Bd25163575031ACDce07538D
        } else if (block.chainid == 43114) {
            dexRouter = IRouter02(0x60aE616a2155Ee3d9A68541Ba4544862310933d4);
        } else if (block.chainid == 250) {
            dexRouter = IRouter02(0xF491e7B69E4244ad4002BC14e878a34207E38c29);
        } else {
            revert();
        }

        lpPair = IFactoryV2(dexRouter.factory()).createPair(dexRouter.WETH(), address(this));

        _liquidityHolders[_owner] = true;

        _isExcludedFromFee[_owner] = true;
        _isExcludedFromFee[devAddress] = true;
        _isExcludedFromFee[address(this)] = true;

        _approve(_owner, address(dexRouter), type(uint256).max);
        _approve(address(this), address(dexRouter), type(uint256).max);
    }

    receive() external payable {}

    function totalSupply() external pure override returns (uint256) {
        return _totalSupply;
    }

    function decimals() external pure override returns (uint8) { 
        return _decimals;
    }

    function symbol() external pure override returns (string memory) { return _symbol; }

    function name() external pure override returns (string memory) { return _name; }

    function getOwner() external view override returns (address) { return _owner; }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function _approve(address sender, address spender, uint256 amount) internal {
        require(sender != address(0), "ERC20: Zero Address");
        require(spender != address(0), "ERC20: Zero Address");

        _allowances[sender][spender] = amount;
        emit Approval(sender, spender, amount);
    }

    function approveContractContingency() external onlyOwner returns (bool) {
        _approve(address(this), address(dexRouter), type(uint256).max);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if (_allowances[sender][msg.sender] != type(uint256).max) {
            _allowances[sender][msg.sender] -= amount;
        }

        return _transfer(sender, recipient, amount);
    }

    function isExcludedFromProtection(address account) external view returns (bool) {
        return _isExcludedFromProtection[account];
    }

    function _hasLimits(address from, address to) internal view returns (bool) {
        return from != _owner
            && to != _owner
            && tx.origin != _owner
            && !_liquidityHolders[to]
            && !_liquidityHolders[from]
            && to != DEAD
            && to != address(0)
            && from != address(this);
    }

    function _transfer(address from, address to, uint256 amount) internal returns (bool) {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if (_hasLimits(from, to)) {
            if(!tradingEnabled) {
                revert("Trading not yet enabled!");
            }
        }

        return finalizeTransfer(from, to, amount);
    }

    function finalizeTransfer(address from, address to, uint256 amount) internal returns (bool) {
        uint256 _taxFee = 0;
        bool other = false;

        if (from == lpPair && to != address(dexRouter)) {
            _taxFee = taxFeeOnBuy;
        } else if (to == lpPair && from != address(dexRouter)) {
            _taxFee = taxFeeOnSell;
        } else {
            other = true;
        }

        if (
                (_isExcludedFromFee[from] || _isExcludedFromFee[to]) ||
                (from != lpPair && to != lpPair)
        ) {
            _taxFee = 0;
        }

        if (!hasLiqBeenAdded) {
            _checkLiquidityAdd(from, to);
            if (!hasLiqBeenAdded && _hasLimits(from, to) && !_isExcludedFromProtection[from] && !_isExcludedFromProtection[to] && !other) {
                revert("Pre-liquidity transfer protection.");
            }
        }

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");

        unchecked {
            _balances[from] = fromBalance - amount;
        }

        uint256 fee = amount.mul(_taxFee).div(1000);
        uint256 transferAmount = amount.sub(fee);

        _balances[to] = _balances[to].add(transferAmount);
        _balances[devAddress] = _balances[devAddress].add(fee);

        emit Transfer(from, to, amount);
        return true;
    }

    function _checkLiquidityAdd(address from, address to) internal {
        require(!hasLiqBeenAdded, "Liquidity already added and marked.");
        if (!_hasLimits(from, to) && to == lpPair) {
            _liquidityHolders[from] = true;
            hasLiqBeenAdded = true;
        }
    }

    function transferOwner(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "Call renounceOwnership to transfer owner to the zero address.");
        require(_newOwner != DEAD, "Call renounceOwnership to transfer owner to the zero address.");
        if (balanceOf(_owner) > 0) {
            finalizeTransfer(_owner, _newOwner, balanceOf(_owner));
        }
        
        address oldOwner = _owner;
        _owner = _newOwner;
        _isExcludedFromFee[_owner] = true;

        emit OwnershipTransferred(oldOwner, _newOwner);
        
    }

    function renounceOwnership() external onlyOwner {
        address oldOwner = _owner;
        _owner = address(0);
        emit OwnershipTransferred(oldOwner, address(0));
    }

    function setExcludedFromProtection(address _account, bool _enabled) external onlyOwner {
        _isExcludedFromProtection[_account] = _enabled;
    }

    function excludePresaleAddresses(address _router, address _presale) external onlyOwner {
        require(allowedPresaleExclusion);
        require(_router != address(this) 
                && _presale != address(this) 
                && lpPair != _router 
                && lpPair != _presale, "Just don't.");
        if (_router == _presale) {
            _liquidityHolders[_presale] = true;
        } else {
            _liquidityHolders[_router] = true;
            _liquidityHolders[_presale] = true;
        }
    }

    function setOperator(address _newOperator) external onlyOwner {
        address oldOperator = operator;
        if (oldOperator != address(0)) {
            _liquidityHolders[oldOperator] = false;
        }
        operator = _newOperator;
        _liquidityHolders[_newOperator] = true;
    }

    function setDevAddress(address _newAddress) external onlyOwner {
        require(devAddress != address(0), "address cannot be 0");
        devAddress = payable(_newAddress);
    }

    function excludeMultipleAccountsFromFees(
        address[] calldata _accounts,
        bool _excluded
    ) public onlyOwner {
        for (uint256 i = 0; i < _accounts.length; i++) {
            _isExcludedFromFee[_accounts[i]] = _excluded;
        }
    }

    function enableTrading() public onlyOwner {
        require(!tradingEnabled, "Trading already enabled!");
        require(hasLiqBeenAdded, "Liquidity must be added.");
        tradingEnabled = true;
        allowedPresaleExclusion = false;
    }

    function setFee(uint256 _taxFeeOnBuy, uint256 _taxFeeOnSell) public onlyOwner {
        require(_taxFeeOnBuy < 40, "Tax cannot be more than 3.");
        require(_taxFeeOnSell < 40, "Tax cannot be more than 3.");
        taxFeeOnBuy = _taxFeeOnBuy;
        taxFeeOnSell = _taxFeeOnSell;
    }

    function setLPPair(address _lpPair) external onlyOwner {
        lpPair = _lpPair;
    }

    function withdrawToken(address _token, address _to) external onlyOwner returns (bool _sent) {
        require(_token != address(0), "_token address cannot be 0");
        uint256 _contractBalance = IERC20(_token).balanceOf(address(this));
        _sent = IERC20(_token).transfer(_to, _contractBalance);
    }

    // withdraw ETH if stuck or someone sends to the address
    function withdrawStuckETH() external onlyOwner {
        bool success;
        (success,) = address(msg.sender).call{value: address(this).balance}("");
    }
}
