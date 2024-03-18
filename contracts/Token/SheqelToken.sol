// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/ERC20.sol)
// Sheqel token version 0.1

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./Context.sol";
import "../../interfaces/Uniswap.sol";
import "./DistributorV2.sol";
import "../Reserve/Reserve.sol";
import "./LiquidityManager.sol";
/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */

// Sheqel Token Contract0
contract SheqelToken is Context, IERC20, IERC20Metadata {
    address public admin;
    bool isFirstLiquidityProviding = true;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;

    uint256 public _totalSupply;

    string private _name;
    string private _symbol;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    Distributor public distributor;
    IUniswapV2Pair public uniswapV2PairContract;

    address public reserveAddress;
    Reserve public reserveContract;
    LiquidityManager liquidityManager;
    address public liquidityManagerAddress;
    address public spookySwapAddress; //0xF491e7B69E4244ad4002BC14e878a34207E38c29; FTM
    address public MDOAddress;
    address public teamAddress;

    address public WFTM = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;// 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83; FTM
    IERC20 public USDC;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(address _reserveAddress, address _MDOAddress, uint256 _tSupply, address _spookyswapAddress, address _USDCAddress) {
        // Setting up the variables
        _name = "Sheqel";
        _symbol = "SHQ";
        _totalSupply = _tSupply;
        _balances[_reserveAddress]= _totalSupply;

        reserveAddress = _reserveAddress;
        reserveContract = Reserve(reserveAddress);
        spookySwapAddress = _spookyswapAddress;
        MDOAddress = _MDOAddress;
        teamAddress = msg.sender;

        USDC = IERC20(_USDCAddress); //IERC20(0x04068DA6C83AFCFA0e13ba15A6696662335D5B75); FTM


        liquidityManager = new LiquidityManager(_USDCAddress, _spookyswapAddress, _reserveAddress);
        liquidityManagerAddress = address(liquidityManager);


        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            spookySwapAddress
        );
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), address(USDC));
            

        uniswapV2Router = _uniswapV2Router;

        uniswapV2PairContract = IUniswapV2Pair(uniswapV2Pair);

        //distributor = new HolderRewarderDistributor(spookySwapAddress, _reserveAddress);

        _isExcludedFromFee[address(this)] = true;


    }

    function setDistributor(address _addr) external {
        require(msg.sender == teamAddress, "Must be team address");
        distributor = Distributor(_addr);
        // Setup initial mint
        //distributor.transferShare(_deployer, _amount);
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        //require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(
            senderBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );

        unchecked {
                _balances[sender] = senderBalance - amount;
        }

        if(recipient != reserveAddress && sender != reserveAddress && !isFirstLiquidityProviding/*&& recipient != uniswapV2Pair && recipient != address(uniswapV2Router)*/){

            // Taking the tax and returning the amount left
            
            uint256 amountRecieved = _takeTax(amount);

            _balances[recipient] += amountRecieved;
            emit Transfer(sender, recipient, amountRecieved);


        }
        else {
            if (isFirstLiquidityProviding == true) {
                isFirstLiquidityProviding = false;
            }
            // Not taxing the transaction
            _balances[recipient] += amount;

            emit Transfer(sender, recipient, amount);

        }


        //_afterTokenTransfer(sender, recipient, amountRecieved);
    }

    /** @dev Creates `amount` tokens and takes all the necessary taxes for the account.
     */
    function _takeTax(uint256 amount)
        internal
        returns (uint256 amountRecieved)
    {
        // Calculating the tax
        uint256 reserve = (amount * 88797) / 10000000;
        uint256 rewards = (amount * 255547) / 10000000;
        uint256 MDO = (amount * 44373) / 10000000;
        uint256 UBR = (amount * 88797) / 10000000;
        uint256 liquidity = (amount * 22187) / 10000000;

        // Adding the liquidity to the contract
        _addToLiquidity(liquidity); 

        // Sending the tokens to the reserve
        _sendToReserve(reserve);

        // Sending the MDO wallet
        _sendToMDO(MDO);

        // Adding to the Universal Basic Reward pool
        _addToUBR(UBR);

        // Adding to the rewards pool
        _addToRewards(rewards);

        return (amount - (reserve + rewards + MDO + UBR + liquidity));
    }

    function _addToRewards(uint256 amount) private {
        _balances[address(distributor)] = _balances[address(distributor)] + (amount);
        //swapTokenToUSDC(address(distributor), amount);

        distributor.addToCurrentShqToRewards(amount);
    }

    function _addToUBR(uint256 amount) private {
        _balances[address(distributor)] = _balances[address(distributor)] + (amount);
        //swapTokenToUSDC(address(distributor), amount);

        distributor.addToCurrentShqToUBR(amount);
    }

    function _addToLiquidity(uint256 amount) private {
        _balances[address(liquidityManager)] = _balances[address(liquidityManager)] + (amount);
        //liquidityManager.addToCurrentShqToLiquidity(amount);
    }

    function _sendToReserve(uint256 amount) private {
        _balances[address(this)] = _balances[address(this)] + (amount);
        swapTokenToUSDC(address(reserveAddress), amount);

        //swapTokenToUSDC(reserveAddress, amount); // Sending the USDC to the reserve
    }

    function _sendToMDO(uint256 amount) private {
        _balances[MDOAddress] = _balances[MDOAddress] + (amount);
    }


    function swapTokenToUSDC(address recipient, uint256 amount) internal {
        _approve(address(this), address(reserveContract), amount);
        reserveContract.sellShq(recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function initiateLiquidityProviding() public {
        liquidityManager.swapAndLiquify();
    }


    function getDistributor() public view returns(address){
        return address(distributor);
    }
}