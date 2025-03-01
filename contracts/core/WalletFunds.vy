# pragma optimize codesize

implements: UserWalletInterface
from interfaces import LegoDex
from interfaces import LegoYield
from interfaces import LegoCommon
from interfaces import LegoCredit
from interfaces import UserWalletInterface

from ethereum.ercs import IERC20
from ethereum.ercs import IERC721

interface WalletConfig:
    def handleSubscriptionsAndPermissions(_agent: address, _action: ActionType, _assets: DynArray[address, MAX_ASSETS], _legoIds: DynArray[uint256, MAX_LEGOS], _cd: CoreData) -> (SubPaymentInfo, SubPaymentInfo): nonpayable
    def getAvailableTxAmount(_asset: address, _wantedAmount: uint256, _shouldCheckTrialFunds: bool, _cd: CoreData = empty(CoreData)) -> uint256: view
    def getTransactionCosts(_agent: address, _action: ActionType, _usdValue: uint256, _cd: CoreData) -> (TxCostInfo, TxCostInfo): view
    def isRecipientAllowed(_recipient: address) -> bool: view
    def owner() -> address: view

interface LegoRegistry:
    def getUnderlyingForUser(_user: address, _asset: address) -> uint256: view
    def getUnderlyingAsset(_vaultToken: address) -> address: view
    def getLegoAddr(_legoId: uint256) -> address: view

interface OracleRegistry:
    def getUsdValue(_asset: address, _amount: uint256, _shouldRaise: bool = False) -> uint256: view
    def getEthUsdValue(_amount: uint256, _shouldRaise: bool = False) -> uint256: view

interface WethContract:
    def withdraw(_amount: uint256): nonpayable
    def deposit(): payable

interface AgentFactory:
    def agentBlacklist(_agentAddr: address) -> bool: view

interface AddyRegistry:
    def getAddy(_addyId: uint256) -> address: view

flag ActionType:
    DEPOSIT
    WITHDRAWAL
    REBALANCE
    TRANSFER
    SWAP
    CONVERSION
    ADD_LIQ
    REMOVE_LIQ
    CLAIM_REWARDS
    BORROW
    REPAY

struct CoreData:
    owner: address
    wallet: address
    walletConfig: address
    addyRegistry: address
    legoRegistry: address
    priceSheets: address
    oracleRegistry: address
    trialFundsAsset: address
    trialFundsInitialAmount: uint256

struct SubPaymentInfo:
    recipient: address
    asset: address
    amount: uint256
    usdValue: uint256
    paidThroughBlock: uint256
    didChange: bool

struct TxCostInfo:
    recipient: address
    asset: address
    amount: uint256
    usdValue: uint256

struct TrialFundsOpp:
    legoId: uint256
    vaultToken: address

event UserWalletDeposit:
    signer: indexed(address)
    asset: indexed(address)
    vaultToken: indexed(address)
    assetAmountDeposited: uint256
    vaultTokenAmountReceived: uint256
    refundAssetAmount: uint256
    usdValue: uint256
    legoId: uint256
    legoAddr: address
    isSignerAgent: bool

event UserWalletWithdrawal:
    signer: indexed(address)
    asset: indexed(address)
    vaultToken: indexed(address)
    assetAmountReceived: uint256
    vaultTokenAmountBurned: uint256
    refundVaultTokenAmount: uint256
    usdValue: uint256
    legoId: uint256
    legoAddr: address
    isSignerAgent: bool

event UserWalletSwap:
    signer: indexed(address)
    tokenIn: indexed(address)
    tokenOut: indexed(address)
    swapAmount: uint256
    toAmount: uint256
    pool: address
    refundAssetAmount: uint256
    usdValue: uint256
    legoId: uint256
    legoAddr: address
    isSignerAgent: bool

event UserWalletBorrow:
    signer: indexed(address)
    borrowAsset: indexed(address)
    borrowAmount: uint256
    usdValue: uint256
    legoId: uint256
    legoAddr: address
    isSignerAgent: bool

event UserWalletRepayDebt:
    signer: indexed(address)
    paymentAsset: indexed(address)
    paymentAmount: uint256
    usdValue: uint256
    remainingDebt: uint256
    legoId: uint256
    legoAddr: indexed(address)
    isSignerAgent: bool

event UserWalletLiquidityAdded:
    signer: indexed(address)
    tokenA: indexed(address)
    tokenB: indexed(address)
    liqAmountA: uint256
    liqAmountB: uint256
    liquidityAdded: uint256
    pool: address
    usdValue: uint256
    refundAssetAmountA: uint256
    refundAssetAmountB: uint256
    nftTokenId: uint256
    legoId: uint256
    legoAddr: address
    isSignerAgent: bool

event UserWalletLiquidityRemoved:
    signer: indexed(address)
    tokenA: indexed(address)
    tokenB: address
    removedAmountA: uint256
    removedAmountB: uint256
    usdValue: uint256
    isDepleted: bool
    liquidityRemoved: uint256
    lpToken: indexed(address)
    refundedLpAmount: uint256
    legoId: uint256
    legoAddr: address
    isSignerAgent: bool

event UserWalletFundsTransferred:
    signer: indexed(address)
    recipient: indexed(address)
    asset: indexed(address)
    amount: uint256
    usdValue: uint256
    isSignerAgent: bool

event UserWalletRewardsClaimed:
    signer: address
    market: address
    rewardToken: address
    rewardAmount: uint256
    proof: bytes32
    legoId: uint256
    legoAddr: address
    isSignerAgent: bool

event UserWalletEthConvertedToWeth:
    signer: indexed(address)
    amount: uint256
    paidEth: uint256
    weth: indexed(address)
    isSignerAgent: bool

event UserWalletWethConvertedToEth:
    signer: indexed(address)
    amount: uint256
    weth: indexed(address)
    isSignerAgent: bool

event UserWalletSubscriptionPaid:
    recipient: indexed(address)
    asset: indexed(address)
    amount: uint256
    usdValue: uint256
    paidThroughBlock: uint256
    isAgent: bool

event UserWalletTransactionFeePaid:
    recipient: indexed(address)
    asset: indexed(address)
    amount: uint256
    usdValue: uint256
    action: ActionType
    isAgent: bool

event UserWalletTrialFundsRecovered:
    asset: indexed(address)
    amountRecovered: uint256
    remainingAmount: uint256

event UserWalletNftRecovered:
    collection: indexed(address)
    nftTokenId: uint256
    owner: indexed(address)

# core
walletConfig: public(address)

# trial funds info
trialFundsAsset: public(address)
trialFundsInitialAmount: public(uint256)

# config
addyRegistry: public(address)
wethAddr: public(address)
initialized: public(bool)

# registry ids
AGENT_FACTORY_ID: constant(uint256) = 1
LEGO_REGISTRY_ID: constant(uint256) = 2
PRICE_SHEETS_ID: constant(uint256) = 3
ORACLE_REGISTRY_ID: constant(uint256) = 4

MAX_ASSETS: constant(uint256) = 25
MAX_REWARDS_ASSETS: constant(uint256) = 10
MAX_LEGOS: constant(uint256) = 20
MAX_INSTRUCTIONS: constant(uint256) = 20

ERC721_RECEIVE_DATA: constant(Bytes[1024]) = b"UnderscoreErc721"
API_VERSION: constant(String[28]) = "0.0.1"


@deploy
def __init__():
    # make sure original reference contract can't be initialized
    self.initialized = True


@payable
@external
def __default__():
    pass


@view
@external
def onERC721Received(_operator: address, _owner: address, _tokenId: uint256, _data: Bytes[1024]) -> bytes4:
    # must implement method for safe NFT transfers
    return method_id("onERC721Received(address,address,uint256,bytes)", output_type=bytes4)


@external
def initialize(
    _walletConfig: address,
    _addyRegistry: address,
    _wethAddr: address,
    _trialFundsAsset: address,
    _trialFundsInitialAmount: uint256,
) -> bool:
    """
    @notice Sets up the initial state of the wallet template
    @dev Can only be called once and sets core contract parameters
    @param _walletConfig The address of the wallet config contract
    @param _addyRegistry The address of the core registry contract
    @param _wethAddr The address of the WETH contract
    @param _trialFundsAsset The address of the gift asset
    @param _trialFundsInitialAmount The amount of the gift asset
    @return bool True if initialization was successful
    """
    assert not self.initialized # dev: can only initialize once
    self.initialized = True

    assert empty(address) not in [_walletConfig, _addyRegistry, _wethAddr] # dev: invalid addrs
    self.walletConfig = _walletConfig
    self.addyRegistry = _addyRegistry
    self.wethAddr = _wethAddr

    # trial funds info
    if _trialFundsAsset != empty(address) and _trialFundsInitialAmount != 0:   
        self.trialFundsAsset = _trialFundsAsset
        self.trialFundsInitialAmount = _trialFundsInitialAmount

    return True


@pure
@external
def apiVersion() -> String[28]:
    """
    @notice Returns the current API version of the contract
    @dev Returns a constant string representing the contract version
    @return String[28] The API version string
    """
    return API_VERSION


###########
# Deposit #
###########


@nonreentrant
@external
def depositTokens(
    _legoId: uint256,
    _asset: address,
    _vault: address,
    _amount: uint256 = max_value(uint256),
) -> (uint256, address, uint256, uint256):
    """
    @notice Deposits tokens into a specified lego integration and vault
    @param _legoId The ID of the lego to use for deposit
    @param _asset The address of the token to deposit
    @param _vault The target vault address
    @param _amount The amount to deposit (defaults to max)
    @return uint256 The amount of assets deposited
    @return address The vault token address
    @return uint256 The amount of vault tokens received
    @return uint256 The usd value of the transaction
    """
    cd: CoreData = self._getCoreData()

    # check permissions / subscription data
    isSignerAgent: bool = self._checkPermsAndHandleSubs(msg.sender, ActionType.DEPOSIT, [_asset], [_legoId], cd)

    # deposit tokens
    assetAmountDeposited: uint256 = 0
    vaultToken: address = empty(address)
    vaultTokenAmountReceived: uint256 = 0
    usdValue: uint256 = 0
    assetAmountDeposited, vaultToken, vaultTokenAmountReceived, usdValue = self._depositTokens(msg.sender, _legoId, _asset, _vault, _amount, isSignerAgent, cd)

    self._handleTransactionFees(msg.sender, isSignerAgent, ActionType.DEPOSIT, usdValue, cd)
    return assetAmountDeposited, vaultToken, vaultTokenAmountReceived, usdValue


@internal
def _depositTokens(
    _signer: address,
    _legoId: uint256,
    _asset: address,
    _vault: address,
    _amount: uint256,
    _isSignerAgent: bool,
    _cd: CoreData,
) -> (uint256, address, uint256, uint256):
    legoAddr: address = staticcall LegoRegistry(_cd.legoRegistry).getLegoAddr(_legoId)
    assert legoAddr != empty(address) # dev: invalid lego

    # finalize amount
    amount: uint256 = staticcall WalletConfig(_cd.walletConfig).getAvailableTxAmount(_asset, _amount, False, _cd)
    assert extcall IERC20(_asset).approve(legoAddr, amount, default_return_value=True) # dev: approval failed

    # deposit into lego partner
    assetAmountDeposited: uint256 = 0
    vaultToken: address = empty(address)
    vaultTokenAmountReceived: uint256 = 0
    refundAssetAmount: uint256 = 0
    usdValue: uint256 = 0
    assetAmountDeposited, vaultToken, vaultTokenAmountReceived, refundAssetAmount, usdValue = extcall LegoYield(legoAddr).depositTokens(_asset, amount, _vault, self)
    assert extcall IERC20(_asset).approve(legoAddr, 0, default_return_value=True) # dev: approval failed

    log UserWalletDeposit(_signer, _asset, vaultToken, assetAmountDeposited, vaultTokenAmountReceived, refundAssetAmount, usdValue, _legoId, legoAddr, _isSignerAgent)
    return assetAmountDeposited, vaultToken, vaultTokenAmountReceived, usdValue


############
# Withdraw #
############


@nonreentrant
@external
def withdrawTokens(
    _legoId: uint256,
    _asset: address,
    _vaultToken: address,
    _vaultTokenAmount: uint256 = max_value(uint256),
) -> (uint256, uint256, uint256):
    """
    @notice Withdraws tokens from a specified lego integration and vault
    @param _legoId The ID of the lego to use for withdrawal
    @param _asset The address of the token to withdraw
    @param _vaultToken The vault token address
    @param _vaultTokenAmount The amount of vault tokens to withdraw (defaults to max)
    @return uint256 The amount of assets received
    @return uint256 The amount of vault tokens burned
    @return uint256 The usd value of the transaction
    """
    cd: CoreData = self._getCoreData()

    # check permissions / subscription data
    isSignerAgent: bool = self._checkPermsAndHandleSubs(msg.sender, ActionType.WITHDRAWAL, [_asset], [_legoId], cd)

    # withdraw from lego partner
    assetAmountReceived: uint256 = 0
    vaultTokenAmountBurned: uint256 = 0
    usdValue: uint256 = 0
    assetAmountReceived, vaultTokenAmountBurned, usdValue = self._withdrawTokens(msg.sender, _legoId, _asset, _vaultToken, _vaultTokenAmount, isSignerAgent, cd)

    self._handleTransactionFees(msg.sender, isSignerAgent, ActionType.WITHDRAWAL, usdValue, cd)
    return assetAmountReceived, vaultTokenAmountBurned, usdValue


@internal
def _withdrawTokens(
    _signer: address,
    _legoId: uint256,
    _asset: address,
    _vaultToken: address,
    _vaultTokenAmount: uint256,
    _isSignerAgent: bool,
    _cd: CoreData,
) -> (uint256, uint256, uint256):
    legoAddr: address = staticcall LegoRegistry(_cd.legoRegistry).getLegoAddr(_legoId)
    assert legoAddr != empty(address) # dev: invalid lego

    # finalize amount, this will look at vault token balance (not always 1:1 with underlying asset)
    withdrawAmount: uint256 = _vaultTokenAmount
    if _vaultToken != empty(address):
        withdrawAmount = staticcall WalletConfig(_cd.walletConfig).getAvailableTxAmount(_vaultToken, _vaultTokenAmount, False, _cd)

        # some vault tokens require max value approval (comp v3)
        assert extcall IERC20(_vaultToken).approve(legoAddr, max_value(uint256), default_return_value=True) # dev: approval failed

    assert withdrawAmount != 0 # dev: nothing to withdraw

    # withdraw from lego partner
    assetAmountReceived: uint256 = 0
    vaultTokenAmountBurned: uint256 = 0
    refundVaultTokenAmount: uint256 = 0
    usdValue: uint256 = 0
    assetAmountReceived, vaultTokenAmountBurned, refundVaultTokenAmount, usdValue = extcall LegoYield(legoAddr).withdrawTokens(_asset, withdrawAmount, _vaultToken, self)

    # zero out approvals
    if _vaultToken != empty(address):
        assert extcall IERC20(_vaultToken).approve(legoAddr, 0, default_return_value=True) # dev: approval failed

    log UserWalletWithdrawal(_signer, _asset, _vaultToken, assetAmountReceived, vaultTokenAmountBurned, refundVaultTokenAmount, usdValue, _legoId, legoAddr, _isSignerAgent)
    return assetAmountReceived, vaultTokenAmountBurned, usdValue


#############
# Rebalance #
#############


@nonreentrant
@external
def rebalance(
    _fromLegoId: uint256,
    _fromAsset: address,
    _fromVaultToken: address,
    _toLegoId: uint256,
    _toVault: address,
    _fromVaultTokenAmount: uint256 = max_value(uint256),
) -> (uint256, address, uint256, uint256):
    """
    @notice Withdraws tokens from one lego and deposits them into another (always same asset)
    @param _fromLegoId The ID of the source lego
    @param _fromAsset The address of the token to rebalance
    @param _fromVaultToken The source vault token address
    @param _toLegoId The ID of the destination lego
    @param _toVault The destination vault address
    @param _fromVaultTokenAmount The vault token amount to rebalance (defaults to max)
    @return uint256 The amount of assets deposited in the destination vault
    @return address The destination vault token address
    @return uint256 The amount of destination vault tokens received
    @return uint256 The usd value of the transaction
    """
    cd: CoreData = self._getCoreData()

    # check permissions / subscription data
    isSignerAgent: bool = self._checkPermsAndHandleSubs(msg.sender, ActionType.REBALANCE, [_fromAsset], [_fromLegoId, _toLegoId], cd)

    # withdraw from the first lego
    assetAmountReceived: uint256 = 0
    na: uint256 = 0
    withdrawUsdValue: uint256 = 0
    assetAmountReceived, na, withdrawUsdValue = self._withdrawTokens(msg.sender, _fromLegoId, _fromAsset, _fromVaultToken, _fromVaultTokenAmount, isSignerAgent, cd)

    # deposit the received assets into the second lego
    assetAmountDeposited: uint256 = 0
    newVaultToken: address = empty(address)
    vaultTokenAmountReceived: uint256 = 0
    depositUsdValue: uint256 = 0
    assetAmountDeposited, newVaultToken, vaultTokenAmountReceived, depositUsdValue = self._depositTokens(msg.sender, _toLegoId, _fromAsset, _toVault, assetAmountReceived, isSignerAgent, cd)

    usdValue: uint256 = max(withdrawUsdValue, depositUsdValue)
    self._handleTransactionFees(msg.sender, isSignerAgent, ActionType.REBALANCE, usdValue, cd)
    return assetAmountDeposited, newVaultToken, vaultTokenAmountReceived, usdValue


########
# Swap #
########


@nonreentrant
@external
def swapTokens(
    _legoId: uint256,
    _tokenIn: address,
    _tokenOut: address,
    _amountIn: uint256 = max_value(uint256),
    _minAmountOut: uint256 = 0,
    _pool: address = empty(address),
) -> (uint256, uint256, uint256):
    """
    @notice Swaps tokens using a specified lego integration
    @dev Validates agent permissions if caller is not the owner
    @param _legoId The ID of the lego to use for swapping
    @param _tokenIn The address of the token to swap from
    @param _tokenOut The address of the token to swap to
    @param _amountIn The amount of input tokens to swap (defaults to max balance)
    @param _minAmountOut The minimum amount of output tokens to receive (defaults to 0)
    @param _pool The pool address to use for swapping (optional)
    @return uint256 The actual amount of input tokens swapped
    @return uint256 The amount of output tokens received
    @return uint256 The usd value of the transaction
    """
    cd: CoreData = self._getCoreData()

    # check permissions / subscription data
    isSignerAgent: bool = self._checkPermsAndHandleSubs(msg.sender, ActionType.SWAP, [_tokenIn, _tokenOut], [_legoId], cd)

    # get lego addr
    legoAddr: address = staticcall LegoRegistry(cd.legoRegistry).getLegoAddr(_legoId)
    assert legoAddr != empty(address) # dev: invalid lego

    # finalize amount
    swapAmount: uint256 = staticcall WalletConfig(cd.walletConfig).getAvailableTxAmount(_tokenIn, _amountIn, True, cd)
    assert extcall IERC20(_tokenIn).approve(legoAddr, swapAmount, default_return_value=True) # dev: approval failed

    # check if swap token of trial funds asset
    isTrialFundsVaultToken: bool = self._isTrialFundsVaultToken(_tokenIn, cd.trialFundsAsset, cd.legoRegistry)

    # swap assets via lego partner
    toAmount: uint256 = 0
    refundAssetAmount: uint256 = 0
    usdValue: uint256 = 0
    swapAmount, toAmount, refundAssetAmount, usdValue = extcall LegoDex(legoAddr).swapTokens(_tokenIn, _tokenOut, swapAmount, _minAmountOut, _pool, self, cd.oracleRegistry)
    assert extcall IERC20(_tokenIn).approve(legoAddr, 0, default_return_value=True) # dev: approval failed

    # make sure they still have enough trial funds
    self._checkTrialFundsPostTx(isTrialFundsVaultToken, cd.trialFundsAsset, cd.trialFundsInitialAmount, cd.legoRegistry)

    self._handleTransactionFees(msg.sender, isSignerAgent, ActionType.SWAP, usdValue, cd)
    log UserWalletSwap(msg.sender, _tokenIn, _tokenOut, swapAmount, toAmount, _pool, refundAssetAmount, usdValue, _legoId, legoAddr, isSignerAgent)
    return swapAmount, toAmount, usdValue


##################
# Borrow + Repay #
##################


# borrow


@nonreentrant
@external
def borrow(
    _legoId: uint256,
    _borrowAsset: address = empty(address),
    _amount: uint256 = max_value(uint256),
) -> (address, uint256, uint256):
    """
    @notice Borrows an asset from a lego integration
    @param _legoId The ID of the lego to borrow from
    @param _borrowAsset The address of the asset to borrow
    @param _amount The amount of the asset to borrow
    @return address The address of the asset borrowed
    @return uint256 The amount of the asset borrowed
    @return uint256 The usd value of the borrowing
    """
    cd: CoreData = self._getCoreData()

    # check permissions / subscription data
    isSignerAgent: bool = self._checkPermsAndHandleSubs(msg.sender, ActionType.BORROW, [_borrowAsset], [_legoId], cd)

    # get lego addr
    legoAddr: address = staticcall LegoRegistry(cd.legoRegistry).getLegoAddr(_legoId)
    assert legoAddr != empty(address) # dev: invalid lego

    # make sure lego can perform this action
    self._checkLegoAccessForAction(legoAddr)

    # borrow via lego partner
    borrowAsset: address = empty(address)
    borrowAmount: uint256 = 0
    usdValue: uint256 = 0
    borrowAsset, borrowAmount, usdValue = extcall LegoCredit(legoAddr).borrow(_borrowAsset, _amount, self, cd.oracleRegistry)

    self._handleTransactionFees(msg.sender, isSignerAgent, ActionType.BORROW, usdValue, cd)
    log UserWalletBorrow(msg.sender, borrowAsset, borrowAmount, usdValue, _legoId, legoAddr, isSignerAgent)
    return borrowAsset, borrowAmount, usdValue


# repay debt


@nonreentrant
@external
def repayDebt(
    _legoId: uint256,
    _paymentAsset: address,
    _paymentAmount: uint256 = max_value(uint256),
) -> (address, uint256, uint256, uint256):
    """
    @notice Repays debt for a lego integration
    @param _legoId The ID of the lego to repay debt for
    @param _paymentAsset The address of the asset to use for repayment
    @param _paymentAmount The amount of the asset to use for repayment
    @return address The address of the asset used for repayment
    @return uint256 The amount of the asset used for repayment
    @return uint256 The usd value of the repayment
    @return uint256 The remaining debt
    """
    cd: CoreData = self._getCoreData()

    # check permissions / subscription data
    isSignerAgent: bool = self._checkPermsAndHandleSubs(msg.sender, ActionType.REPAY, [_paymentAsset], [_legoId], cd)

    # get lego addr
    legoAddr: address = staticcall LegoRegistry(cd.legoRegistry).getLegoAddr(_legoId)
    assert legoAddr != empty(address) # dev: invalid lego

    # make sure lego can perform this action
    self._checkLegoAccessForAction(legoAddr)

    # finalize amount
    paymentAmount: uint256 = staticcall WalletConfig(cd.walletConfig).getAvailableTxAmount(_paymentAsset, _paymentAmount, True, cd)
    assert extcall IERC20(_paymentAsset).approve(legoAddr, paymentAmount, default_return_value=True) # dev: approval failed

    # check if payment asset is trial funds asset
    isTrialFundsVaultToken: bool = self._isTrialFundsVaultToken(_paymentAsset, cd.trialFundsAsset, cd.legoRegistry)

    # repay debt via lego partner
    paymentAsset: address = empty(address)
    usdValue: uint256 = 0
    remainingDebt: uint256 = 0
    paymentAsset, paymentAmount, usdValue, remainingDebt = extcall LegoCredit(legoAddr).repayDebt(_paymentAsset, paymentAmount, self, cd.oracleRegistry)
    assert extcall IERC20(_paymentAsset).approve(legoAddr, 0, default_return_value=True) # dev: approval failed

    # make sure they still have enough trial funds
    self._checkTrialFundsPostTx(isTrialFundsVaultToken, cd.trialFundsAsset, cd.trialFundsInitialAmount, cd.legoRegistry)

    self._handleTransactionFees(msg.sender, isSignerAgent, ActionType.REPAY, usdValue, cd)
    log UserWalletRepayDebt(msg.sender, paymentAsset, paymentAmount, usdValue, remainingDebt, _legoId, legoAddr, isSignerAgent)
    return paymentAsset, paymentAmount, usdValue, remainingDebt


#################
# Claim Rewards #
#################


@nonreentrant
@external
def claimRewards(
    _legoId: uint256,
    _market: address = empty(address),
    _rewardToken: address = empty(address),
    _rewardAmount: uint256 = max_value(uint256),
    _proof: bytes32 = empty(bytes32),
):
    """
    @notice Claims rewards from a lego integration
    @param _legoId The lego ID to claim rewards from
    @param _market The market to claim rewards from
    @param _rewardToken The reward token to claim
    @param _rewardAmount The reward amount to claim
    @param _proof The proof to verify the rewards
    """
    cd: CoreData = self._getCoreData()

    # pass in empty action, lego ids, and assets here
    isSignerAgent: bool = self._checkPermsAndHandleSubs(msg.sender, ActionType.CLAIM_REWARDS, [_rewardToken], [_legoId], cd)

    # get lego addr
    legoAddr: address = staticcall LegoRegistry(cd.legoRegistry).getLegoAddr(_legoId)
    assert legoAddr != empty(address) # dev: invalid lego

    # make sure lego has access to claim rewards
    self._checkLegoAccessForAction(legoAddr)

    # claim rewards
    extcall LegoCommon(legoAddr).claimRewards(self, _market, _rewardToken, _rewardAmount, _proof)
    log UserWalletRewardsClaimed(msg.sender, _market, _rewardToken, _rewardAmount, _proof, _legoId, legoAddr, isSignerAgent)


#################
# Add Liquidity #
#################


@nonreentrant
@external
def addLiquidity(
    _legoId: uint256,
    _nftAddr: address,
    _nftTokenId: uint256,
    _pool: address,
    _tokenA: address,
    _tokenB: address,
    _amountA: uint256 = max_value(uint256),
    _amountB: uint256 = max_value(uint256),
    _tickLower: int24 = min_value(int24),
    _tickUpper: int24 = max_value(int24),
    _minAmountA: uint256 = 0,
    _minAmountB: uint256 = 0,
    _minLpAmount: uint256 = 0,
) -> (uint256, uint256, uint256, uint256, uint256):
    """
    @notice Adds liquidity to a pool
    @param _legoId The ID of the lego to use for adding liquidity
    @param _nftAddr The address of the NFT token contract
    @param _nftTokenId The ID of the NFT token to use for adding liquidity
    @param _pool The address of the pool to add liquidity to
    @param _tokenA The address of the first token to add liquidity
    @param _tokenB The address of the second token to add liquidity
    @param _amountA The amount of the first token to add liquidity
    @param _amountB The amount of the second token to add liquidity
    @param _tickLower The lower tick of the liquidity range
    @param _tickUpper The upper tick of the liquidity range
    @param _minAmountA The minimum amount of the first token to add liquidity
    @param _minAmountB The minimum amount of the second token to add liquidity
    @param _minLpAmount The minimum amount of lp token amount to receive
    @return uint256 The amount of liquidity added
    @return uint256 The amount of the first token added
    @return uint256 The amount of the second token added
    @return uint256 The usd value of the liquidity added
    @return uint256 The ID of the NFT token used for adding liquidity
    """
    cd: CoreData = self._getCoreData()

    # check permissions / subscription data
    isSignerAgent: bool = self._checkPermsAndHandleSubs(msg.sender, ActionType.ADD_LIQ, [_tokenA, _tokenB], [_legoId], cd)

    # get lego addr
    legoAddr: address = staticcall LegoRegistry(cd.legoRegistry).getLegoAddr(_legoId)
    assert legoAddr != empty(address) # dev: invalid lego

    # token a
    amountA: uint256 = 0
    isTrialFundsVaultTokenA: bool = False
    if _amountA != 0:
        amountA = staticcall WalletConfig(cd.walletConfig).getAvailableTxAmount(_tokenA, _amountA, True, cd)
        assert extcall IERC20(_tokenA).approve(legoAddr, amountA, default_return_value=True) # dev: approval failed
        isTrialFundsVaultTokenA = self._isTrialFundsVaultToken(_tokenA, cd.trialFundsAsset, cd.legoRegistry)

    # token b
    amountB: uint256 = 0
    isTrialFundsVaultTokenB: bool = False
    if _amountB != 0:
        amountB = staticcall WalletConfig(cd.walletConfig).getAvailableTxAmount(_tokenB, _amountB, True, cd)
        assert extcall IERC20(_tokenB).approve(legoAddr, amountB, default_return_value=True) # dev: approval failed
        isTrialFundsVaultTokenB = self._isTrialFundsVaultToken(_tokenB, cd.trialFundsAsset, cd.legoRegistry)

    # transfer nft to lego (if applicable)
    hasNftLiqPosition: bool = _nftAddr != empty(address) and _nftTokenId != 0
    if hasNftLiqPosition:
        extcall IERC721(_nftAddr).safeTransferFrom(self, legoAddr, _nftTokenId, ERC721_RECEIVE_DATA)

    # add liquidity via lego partner
    liquidityAdded: uint256 = 0
    liqAmountA: uint256 = 0
    liqAmountB: uint256 = 0
    usdValue: uint256 = 0
    refundAssetAmountA: uint256 = 0
    refundAssetAmountB: uint256 = 0
    nftTokenId: uint256 = 0
    liquidityAdded, liqAmountA, liqAmountB, usdValue, refundAssetAmountA, refundAssetAmountB, nftTokenId = extcall LegoDex(legoAddr).addLiquidity(_nftTokenId, _pool, _tokenA, _tokenB, _tickLower, _tickUpper, amountA, amountB, _minAmountA, _minAmountB, _minLpAmount, self, cd.oracleRegistry)

    # validate the nft came back
    if hasNftLiqPosition:
        assert staticcall IERC721(_nftAddr).ownerOf(_nftTokenId) == self # dev: nft not returned

    # token a
    self._checkTrialFundsPostTx(isTrialFundsVaultTokenA, cd.trialFundsAsset, cd.trialFundsInitialAmount, cd.legoRegistry)
    if amountA != 0:
        assert extcall IERC20(_tokenA).approve(legoAddr, 0, default_return_value=True) # dev: approval failed

    # token b
    self._checkTrialFundsPostTx(isTrialFundsVaultTokenB, cd.trialFundsAsset, cd.trialFundsInitialAmount, cd.legoRegistry)
    if amountB != 0:
        assert extcall IERC20(_tokenB).approve(legoAddr, 0, default_return_value=True) # dev: approval failed

    self._handleTransactionFees(msg.sender, isSignerAgent, ActionType.ADD_LIQ, usdValue, cd)
    log UserWalletLiquidityAdded(msg.sender, _tokenA, _tokenB, liqAmountA, liqAmountB, liquidityAdded, _pool, usdValue, refundAssetAmountA, refundAssetAmountB, nftTokenId, _legoId, legoAddr, isSignerAgent)
    return liquidityAdded, liqAmountA, liqAmountB, usdValue, nftTokenId


####################
# Remove Liquidity #
####################


@nonreentrant
@external
def removeLiquidity(
    _legoId: uint256,
    _nftAddr: address,
    _nftTokenId: uint256,
    _pool: address,
    _tokenA: address,
    _tokenB: address,
    _liqToRemove: uint256 = max_value(uint256),
    _minAmountA: uint256 = 0,
    _minAmountB: uint256 = 0,
) -> (uint256, uint256, uint256, bool):
    """
    @notice Removes liquidity from a pool
    @param _legoId The ID of the lego to use for removing liquidity
    @param _nftAddr The address of the NFT token contract
    @param _nftTokenId The ID of the NFT token to use for removing liquidity
    @param _pool The address of the pool to remove liquidity from
    @param _tokenA The address of the first token to remove liquidity
    @param _tokenB The address of the second token to remove liquidity
    @param _liqToRemove The amount of liquidity to remove
    @param _minAmountA The minimum amount of the first token to remove liquidity
    @param _minAmountB The minimum amount of the second token to remove liquidity
    @return uint256 The amount of the first token removed
    @return uint256 The amount of the second token removed
    @return uint256 The usd value of the liquidity removed
    @return bool True if the liquidity moved to lego contract was depleted, false otherwise
    """
    cd: CoreData = self._getCoreData()

    # check permissions / subscription data
    isSignerAgent: bool = self._checkPermsAndHandleSubs(msg.sender, ActionType.REMOVE_LIQ, [_tokenA, _tokenB], [_legoId], cd)

    # get lego addr
    legoAddr: address = staticcall LegoRegistry(cd.legoRegistry).getLegoAddr(_legoId)
    assert legoAddr != empty(address) # dev: invalid lego

    lpToken: address = empty(address)
    liqToRemove: uint256 = _liqToRemove

    # transfer nft to lego (if applicable)
    hasNftLiqPosition: bool = _nftAddr != empty(address) and _nftTokenId != 0
    if hasNftLiqPosition:
        extcall IERC721(_nftAddr).safeTransferFrom(self, legoAddr, _nftTokenId, ERC721_RECEIVE_DATA)

    # handle lp token
    else:
        lpToken = staticcall LegoDex(legoAddr).getLpToken(_pool)
        liqToRemove = staticcall WalletConfig(cd.walletConfig).getAvailableTxAmount(lpToken, liqToRemove, False, cd)
        assert extcall IERC20(lpToken).approve(legoAddr, liqToRemove, default_return_value=True) # dev: approval failed

    # remove liquidity via lego partner
    amountA: uint256 = 0
    amountB: uint256 = 0
    usdValue: uint256 = 0
    liquidityRemoved: uint256 = 0
    refundedLpAmount: uint256 = 0
    isDepleted: bool = False
    amountA, amountB, usdValue, liquidityRemoved, refundedLpAmount, isDepleted = extcall LegoDex(legoAddr).removeLiquidity(_nftTokenId, _pool, _tokenA, _tokenB, lpToken, liqToRemove, _minAmountA, _minAmountB, self, cd.oracleRegistry)

    # validate the nft came back, reset lp token approvals
    if hasNftLiqPosition:
        if not isDepleted:
            assert staticcall IERC721(_nftAddr).ownerOf(_nftTokenId) == self # dev: nft not returned
    else:
        assert extcall IERC20(lpToken).approve(legoAddr, 0, default_return_value=True) # dev: approval failed

    self._handleTransactionFees(msg.sender, isSignerAgent, ActionType.REMOVE_LIQ, usdValue, cd)
    log UserWalletLiquidityRemoved(msg.sender, _tokenA, _tokenB, amountA, amountB, usdValue, isDepleted, liquidityRemoved, lpToken, refundedLpAmount, _legoId, legoAddr, isSignerAgent)
    return amountA, amountB, usdValue, isDepleted


##################
# Transfer Funds #
##################


@nonreentrant
@external
def transferFunds(
    _recipient: address,
    _amount: uint256 = max_value(uint256),
    _asset: address = empty(address),
) -> (uint256, uint256):
    """
    @notice Transfers funds to a specified recipient
    @dev Handles both ETH and token transfers with optional amount specification
    @param _recipient The address to receive the funds
    @param _amount The amount to transfer (defaults to max)
    @param _asset The token address (empty for ETH)
    @return uint256 The amount of funds transferred
    @return uint256 The usd value of the transaction
    """
    cd: CoreData = self._getCoreData()

    # check permissions / subscription data
    isSignerAgent: bool = self._checkPermsAndHandleSubs(msg.sender, ActionType.TRANSFER, [_asset], [], cd)

    # transfer funds
    amount: uint256 = 0
    usdValue: uint256 = 0
    amount, usdValue = self._transferFunds(msg.sender, _recipient, _amount, _asset, isSignerAgent, cd)

    self._handleTransactionFees(msg.sender, isSignerAgent, ActionType.TRANSFER, usdValue, cd)
    return amount, usdValue


@internal
def _transferFunds(
    _signer: address,
    _recipient: address,
    _amount: uint256,
    _asset: address,
    _isSignerAgent: bool,
    _cd: CoreData,
) -> (uint256, uint256):
    amount: uint256 = 0
    usdValue: uint256 = 0

    # validate recipient
    if _recipient != _cd.owner:
        assert staticcall WalletConfig(_cd.walletConfig).isRecipientAllowed(_recipient) # dev: recipient not allowed

    # handle eth
    if _asset == empty(address):
        amount = min(_amount, self.balance)
        assert amount != 0 # dev: nothing to transfer
        send(_recipient, amount)
        usdValue = staticcall OracleRegistry(_cd.oracleRegistry).getEthUsdValue(amount)

    # erc20 tokens
    else:

        # check if vault token of trial funds asset
        isTrialFundsVaultToken: bool = self._isTrialFundsVaultToken(_asset, _cd.trialFundsAsset, _cd.legoRegistry)

        # perform transfer
        amount = staticcall WalletConfig(_cd.walletConfig).getAvailableTxAmount(_asset, _amount, True, _cd)
        assert extcall IERC20(_asset).transfer(_recipient, amount, default_return_value=True) # dev: transfer failed
        usdValue = staticcall OracleRegistry(_cd.oracleRegistry).getUsdValue(_asset, amount)

        # make sure they still have enough trial funds
        self._checkTrialFundsPostTx(isTrialFundsVaultToken, _cd.trialFundsAsset, _cd.trialFundsInitialAmount, _cd.legoRegistry)

    log UserWalletFundsTransferred(_signer, _recipient, _asset, amount, usdValue, _isSignerAgent)
    return amount, usdValue


################
# Wrapped ETH #
################


# eth -> weth


@nonreentrant
@payable
@external
def convertEthToWeth(
    _amount: uint256 = max_value(uint256),
    _depositLegoId: uint256 = 0,
    _depositVault: address = empty(address),
) -> (uint256, address, uint256):
    """
    @notice Converts ETH to WETH and optionally deposits into a lego integration and vault
    @param _amount The amount of ETH to convert (defaults to max)
    @param _depositLegoId The lego ID to use for deposit (optional)
    @param _depositVault The vault address for deposit (optional)
    @return uint256 The amount of assets deposited (if deposit performed)
    @return address The vault token address (if deposit performed)
    @return uint256 The amount of vault tokens received (if deposit performed)
    """
    cd: CoreData = self._getCoreData()
    weth: address = self.wethAddr

    # check permissions / subscription data
    isSignerAgent: bool = self._checkPermsAndHandleSubs(msg.sender, ActionType.CONVERSION, [weth], [_depositLegoId], cd)

    # convert eth to weth
    amount: uint256 = min(_amount, self.balance)
    assert amount != 0 # dev: nothing to convert
    extcall WethContract(weth).deposit(value=amount)
    log UserWalletEthConvertedToWeth(msg.sender, amount, msg.value, weth, isSignerAgent)

    # deposit weth into lego partner
    vaultToken: address = empty(address)
    vaultTokenAmountReceived: uint256 = 0
    if _depositLegoId != 0:
        depositUsdValue: uint256 = 0
        amount, vaultToken, vaultTokenAmountReceived, depositUsdValue = self._depositTokens(msg.sender, _depositLegoId, weth, _depositVault, amount, isSignerAgent, cd)
        self._handleTransactionFees(msg.sender, isSignerAgent, ActionType.DEPOSIT, depositUsdValue, cd)

    return amount, vaultToken, vaultTokenAmountReceived


# weth -> eth


@nonreentrant
@external
def convertWethToEth(
    _amount: uint256 = max_value(uint256),
    _recipient: address = empty(address),
    _withdrawLegoId: uint256 = 0,
    _withdrawVaultToken: address = empty(address),
) -> uint256:
    """
    @notice Converts WETH to ETH and optionally withdraws from a vault first
    @param _amount The amount of WETH to convert (defaults to max)
    @param _recipient The address to receive the ETH (optional)
    @param _withdrawLegoId The lego ID to withdraw from (optional)
    @param _withdrawVaultToken The vault token to withdraw (optional)
    @return uint256 The amount of ETH received
    """
    cd: CoreData = self._getCoreData()
    weth: address = self.wethAddr

    # check permissions / subscription data
    isSignerAgent: bool = self._checkPermsAndHandleSubs(msg.sender, ActionType.CONVERSION, [weth], [_withdrawLegoId], cd)

    # withdraw weth from lego partner (if applicable)
    amount: uint256 = _amount
    usdValue: uint256 = 0
    if _withdrawLegoId != 0:
        _na: uint256 = 0
        amount, _na, usdValue = self._withdrawTokens(msg.sender, _withdrawLegoId, weth, _withdrawVaultToken, _amount, isSignerAgent, cd)
        self._handleTransactionFees(msg.sender, isSignerAgent, ActionType.WITHDRAWAL, usdValue, cd)

    # convert weth to eth
    amount = min(amount, staticcall IERC20(weth).balanceOf(self))
    assert amount != 0 # dev: nothing to convert
    extcall WethContract(weth).withdraw(amount)
    log UserWalletWethConvertedToEth(msg.sender, amount, weth, isSignerAgent)

    # transfer eth to recipient (if applicable)
    if _recipient != empty(address):
        amount, usdValue = self._transferFunds(msg.sender, _recipient, amount, empty(address), isSignerAgent, cd)
        self._handleTransactionFees(msg.sender, isSignerAgent, ActionType.TRANSFER, usdValue, cd)

    return amount


#############
# Utilities #
#############


@view
@internal
def _getCoreData() -> CoreData:
    addyRegistry: address = self.addyRegistry
    walletConfig: address = self.walletConfig
    return CoreData(
        owner=staticcall WalletConfig(walletConfig).owner(),
        wallet=self,
        walletConfig=walletConfig,
        addyRegistry=addyRegistry,
        legoRegistry=staticcall AddyRegistry(addyRegistry).getAddy(LEGO_REGISTRY_ID),
        priceSheets=staticcall AddyRegistry(addyRegistry).getAddy(PRICE_SHEETS_ID),
        oracleRegistry=staticcall AddyRegistry(addyRegistry).getAddy(ORACLE_REGISTRY_ID),
        trialFundsAsset=self.trialFundsAsset,
        trialFundsInitialAmount=self.trialFundsInitialAmount,
    )


# payments (subscriptions, transaction fees)


@internal
def _checkPermsAndHandleSubs(
    _signer: address,
    _action: ActionType,
    _assets: DynArray[address, MAX_ASSETS],
    _legoIds: DynArray[uint256, MAX_LEGOS],
    _cd: CoreData,
) -> bool:
    agent: address = _signer
    if _signer == _cd.owner:
        agent = empty(address)

    # check if agent is blacklisted
    if agent != empty(address):
        agentFactory: address = staticcall AddyRegistry(_cd.addyRegistry).getAddy(AGENT_FACTORY_ID)
        assert not staticcall AgentFactory(agentFactory).agentBlacklist(agent) # dev: agent is blacklisted

    # handle subscriptions and permissions
    protocolSub: SubPaymentInfo = empty(SubPaymentInfo)
    agentSub: SubPaymentInfo = empty(SubPaymentInfo)
    protocolSub, agentSub = extcall WalletConfig(_cd.walletConfig).handleSubscriptionsAndPermissions(agent, _action, _assets, _legoIds, _cd)

    # handle protocol subscription payment
    if protocolSub.amount != 0:
        assert extcall IERC20(protocolSub.asset).transfer(protocolSub.recipient, protocolSub.amount, default_return_value=True) # dev: protocol subscription payment failed
        log UserWalletSubscriptionPaid(protocolSub.recipient, protocolSub.asset, protocolSub.amount, protocolSub.usdValue, protocolSub.paidThroughBlock, False)

    # handle agent subscription payment
    if agentSub.amount != 0:
        assert extcall IERC20(agentSub.asset).transfer(agentSub.recipient, agentSub.amount, default_return_value=True) # dev: agent subscription payment failed
        log UserWalletSubscriptionPaid(agent, agentSub.asset, agentSub.amount, agentSub.usdValue, agentSub.paidThroughBlock, True)

    return agent != empty(address)


@internal
def _handleTransactionFees(
    _agent: address,
    _isSignerAgent: bool,
    _action: ActionType,
    _usdValue: uint256,
    _cd: CoreData,
):
    if not _isSignerAgent or _usdValue == 0:
        return

    # get costs
    protocolCost: TxCostInfo = empty(TxCostInfo)
    agentCost: TxCostInfo = empty(TxCostInfo)
    protocolCost, agentCost = staticcall WalletConfig(_cd.walletConfig).getTransactionCosts(_agent, _action, _usdValue, _cd)

    # make payment
    self._payTransactionFees(protocolCost, agentCost, _action)


@internal
def _payTransactionFees(_protocolCost: TxCostInfo, _agentCost: TxCostInfo, _action: ActionType):
    
    # protocol tx fees
    if _protocolCost.amount != 0:
        assert extcall IERC20(_protocolCost.asset).transfer(_protocolCost.recipient, _protocolCost.amount, default_return_value=True) # dev: protocol tx fee payment failed
        log UserWalletTransactionFeePaid(_protocolCost.recipient, _protocolCost.asset, _protocolCost.amount, _protocolCost.usdValue, _action, False)

    # agent tx fees
    if _agentCost.amount != 0:
        assert extcall IERC20(_agentCost.asset).transfer(_agentCost.recipient, _agentCost.amount, default_return_value=True) # dev: agent tx fee payment failed
        log UserWalletTransactionFeePaid(_agentCost.recipient, _agentCost.asset, _agentCost.amount, _agentCost.usdValue, _action, True)


# allow lego to perform action


@internal
def _checkLegoAccessForAction(_legoAddr: address):
    targetAddr: address = empty(address)
    accessAbi: String[64] = empty(String[64])
    numInputs: uint256 = 0
    targetAddr, accessAbi, numInputs = staticcall LegoCommon(_legoAddr).getAccessForLego(self)

    # nothing to do here
    if targetAddr == empty(address):
        return

    method_abi: bytes4 = convert(slice(keccak256(accessAbi), 0, 4), bytes4)
    success: bool = False
    response: Bytes[32] = b""

    # assumes input is: lego addr (operator)
    if numInputs == 1:
        success, response = raw_call(
            targetAddr,
            concat(
                method_abi,
                convert(_legoAddr, bytes32),
            ),
            revert_on_failure=False,
            max_outsize=32,
        )
    
    # assumes input (and order) is: user addr (owner), lego addr (operator)
    elif numInputs == 2:
        success, response = raw_call(
            targetAddr,
            concat(
                method_abi,
                convert(self, bytes32),
                convert(_legoAddr, bytes32),
            ),
            revert_on_failure=False,
            max_outsize=32,
        )

    # assumes input (and order) is: user addr (owner), lego addr (operator), allowed bool
    elif numInputs == 3:
        success, response = raw_call(
            targetAddr,
            concat(
                method_abi,
                convert(self, bytes32),
                convert(_legoAddr, bytes32),
                convert(True, bytes32),
            ),
            revert_on_failure=False,
            max_outsize=32,
        )

    assert success # dev: failed to set operator


# trial funds


@view
@internal
def _isTrialFundsVaultToken(_asset: address, _trialFundsAsset: address, _legoRegistry: address) -> bool:
    if _trialFundsAsset == empty(address) or _asset == _trialFundsAsset:
        return False
    return _trialFundsAsset == staticcall LegoRegistry(_legoRegistry).getUnderlyingAsset(_asset)


@view
@internal
def _checkTrialFundsPostTx(_isTrialFundsVaultToken: bool, _trialFundsAsset: address, _trialFundsInitialAmount: uint256, _legoRegistry: address):
    if not _isTrialFundsVaultToken:
        return
    postUnderlying: uint256 = staticcall LegoRegistry(_legoRegistry).getUnderlyingForUser(self, _trialFundsAsset)
    assert postUnderlying >= _trialFundsInitialAmount # dev: cannot transfer trial funds vault token


@external
def recoverTrialFunds(_opportunities: DynArray[TrialFundsOpp, MAX_LEGOS] = []) -> bool:
    """
    @notice Recovers trial funds from the wallet
    @param _opportunities Array of trial funds opportunities
    @return bool True if trial funds were recovered successfully
    """
    cd: CoreData = self._getCoreData()
    agentFactory: address = staticcall AddyRegistry(cd.addyRegistry).getAddy(AGENT_FACTORY_ID)
    assert msg.sender == agentFactory # dev: no perms

    # validation
    assert cd.trialFundsAsset != empty(address) # dev: no trial funds asset
    assert cd.trialFundsInitialAmount != 0 # dev: no trial funds amount

    # iterate through clawback data
    balanceAvail: uint256 = staticcall IERC20(cd.trialFundsAsset).balanceOf(self)
    for i: uint256 in range(len(_opportunities), bound=MAX_LEGOS):
        if balanceAvail >= cd.trialFundsInitialAmount:
            break

        # get vault token data
        opp: TrialFundsOpp = _opportunities[i]
        vaultTokenBal: uint256 = staticcall IERC20(opp.vaultToken).balanceOf(self)
        if vaultTokenBal == 0:
            continue

        # withdraw from lego partner
        assetAmountReceived: uint256 = 0
        na1: uint256 = 0
        na2: uint256 = 0
        assetAmountReceived, na1, na2 = self._withdrawTokens(agentFactory, opp.legoId, cd.trialFundsAsset, opp.vaultToken, vaultTokenBal, False, cd)
        balanceAvail += assetAmountReceived

        # deposit any extra balance back lego
        if balanceAvail > cd.trialFundsInitialAmount:
            self._depositTokens(agentFactory, opp.legoId, cd.trialFundsAsset, opp.vaultToken, balanceAvail - cd.trialFundsInitialAmount, False, cd)
            break

    # transfer back to agent factory
    amountRecovered: uint256 = min(cd.trialFundsInitialAmount, staticcall IERC20(cd.trialFundsAsset).balanceOf(self))
    assert amountRecovered != 0 # dev: no funds to transfer
    assert extcall IERC20(cd.trialFundsAsset).transfer(agentFactory, amountRecovered, default_return_value=True) # dev: trial funds transfer failed

    # update trial funds data
    remainingTrialFunds: uint256 = cd.trialFundsInitialAmount - amountRecovered
    self.trialFundsInitialAmount = remainingTrialFunds
    if remainingTrialFunds == 0:
        self.trialFundsAsset = empty(address)

    log UserWalletTrialFundsRecovered(cd.trialFundsAsset, amountRecovered, remainingTrialFunds)
    return True


# recover nft


@external
def recoverNft(_collection: address, _nftTokenId: uint256) -> bool:
    """
    @notice Recovers an NFT from the wallet
    @param _collection The collection address
    @param _nftTokenId The token ID of the NFT
    @return bool True if the NFT was recovered successfully
    """
    owner: address = staticcall WalletConfig(self.walletConfig).owner()
    assert msg.sender == owner # dev: no perms

    if staticcall IERC721(_collection).ownerOf(_nftTokenId) != self:
        return False

    extcall IERC721(_collection).safeTransferFrom(self, owner, _nftTokenId)
    log UserWalletNftRecovered(_collection, _nftTokenId, owner)
    return True