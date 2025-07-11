# SPDX-License-Identifier: BUSL-1.1
# Underscore Protocol License: https://github.com/underscore-finance/underscore/blob/main/licenses/BUSL_LICENSE
# Underscore Protocol (C) 2025 Hightop Financial, Inc.
# @version 0.4.1

initializes: own
exports: own.__interface__

import contracts.modules.Ownership as own
from interfaces import UserWalletInterface
from ethereum.ercs import IERC20

interface UserWalletCustom:
    def swapTokens(_swapInstructions: DynArray[SwapInstruction, MAX_SWAP_INSTRUCTIONS]) -> (uint256, uint256, uint256): nonpayable

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

struct Signature:
    signature: Bytes[65]
    signer: address
    expiration: uint256

struct SwapInstruction:
    legoId: uint256
    amountIn: uint256
    minAmountOut: uint256
    tokenPath: DynArray[address, MAX_TOKEN_PATH]
    poolPath: DynArray[address, MAX_TOKEN_PATH - 1]

struct ActionInstruction:
    usePrevAmountOut: bool
    action: ActionType
    legoId: uint256
    asset: address
    vault: address
    amount: uint256
    altLegoId: uint256
    altAsset: address
    altVault: address
    altAmount: uint256
    minAmountOut: uint256
    pool: address
    proof: bytes32
    nftAddr: address
    nftTokenId: uint256
    tickLower: int24
    tickUpper: int24
    minAmountA: uint256
    minAmountB: uint256
    minLpAmount: uint256
    liqToRemove: uint256
    recipient: address
    isWethToEthConversion: bool
    swapInstructions: DynArray[SwapInstruction, MAX_SWAP_INSTRUCTIONS]
    hasVaultToken: bool

event AgentFundsRecovered:
    asset: indexed(address)
    recipient: indexed(address)
    balance: uint256

usedSignatures: public(HashMap[Bytes[65], bool])

# eip-712
ECRECOVER_PRECOMPILE: constant(address) = 0x0000000000000000000000000000000000000001
DOMAIN_TYPE_HASH: constant(bytes32) = keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)')
DEPOSIT_TYPE_HASH: constant(bytes32) = keccak256('Deposit(address userWallet,uint256 legoId,address asset,address vault,uint256 amount,uint256 expiration)')
WITHDRAWAL_TYPE_HASH: constant(bytes32) = keccak256('Withdrawal(address userWallet,uint256 legoId,address asset,address vaultAddr,uint256 withdrawAmount,bool hasVaultToken,uint256 expiration)')
REBALANCE_TYPE_HASH: constant(bytes32) = keccak256('Rebalance(address userWallet,uint256 fromLegoId,address fromAsset,address fromVaultAddr,uint256 toLegoId,address toVaultAddr,uint256 fromVaultAmount,bool hasFromVaultToken,uint256 expiration)')
SWAP_ACTION_TYPE_HASH: constant(bytes32) =  keccak256('Swap(address userWallet,SwapInstruction[] swapInstructions,uint256 expiration)')
SWAP_INSTRUCTION_TYPE_HASH: constant(bytes32) = keccak256('SwapInstruction(uint256 legoId,uint256 amountIn,uint256 minAmountOut,address[] tokenPath,address[] poolPath)')
ADD_LIQ_TYPE_HASH: constant(bytes32) = keccak256('AddLiquidity(address userWallet,uint256 legoId,address nftAddr,uint256 nftTokenId,address pool,address tokenA,address tokenB,uint256 amountA,uint256 amountB,int24 tickLower,int24 tickUpper,uint256 minAmountA,uint256 minAmountB,uint256 minLpAmount,uint256 expiration)')
REMOVE_LIQ_TYPE_HASH: constant(bytes32) = keccak256('RemoveLiquidity(address userWallet,uint256 legoId,address nftAddr,uint256 nftTokenId,address pool,address tokenA,address tokenB,uint256 liqToRemove,uint256 minAmountA,uint256 minAmountB,uint256 expiration)')
TRANSFER_TYPE_HASH: constant(bytes32) = keccak256('Transfer(address userWallet,address recipient,uint256 amount,address asset,uint256 expiration)')
ETH_TO_WETH_TYPE_HASH: constant(bytes32) = keccak256('EthToWeth(address userWallet,uint256 amount,uint256 depositLegoId,address depositVault,uint256 expiration)')
WETH_TO_ETH_TYPE_HASH: constant(bytes32) = keccak256('WethToEth(address userWallet,uint256 amount,address recipient,uint256 withdrawLegoId,address withdrawVaultAddr,bool hasWithdrawVaultToken,uint256 expiration)')
CLAIM_REWARDS_TYPE_HASH: constant(bytes32) = keccak256('ClaimRewards(address userWallet,uint256 legoId,address market,address rewardToken,uint256 rewardAmount,bytes32 proof,uint256 expiration)')
BORROW_TYPE_HASH: constant(bytes32) = keccak256('Borrow(address userWallet,uint256 legoId,address borrowAsset,uint256 amount,uint256 expiration)')
REPAY_TYPE_HASH: constant(bytes32) = keccak256('Repay(address userWallet,uint256 legoId,address paymentAsset,uint256 paymentAmount,uint256 expiration)')
BATCH_ACTIONS_TYPE_HASH: constant(bytes32) =  keccak256('BatchActions(address userWallet,ActionInstruction[] instructions,uint256 expiration)')
ACTION_INSTRUCTION_TYPE_HASH: constant(bytes32) = keccak256('ActionInstruction(bool usePrevAmountOut,uint256 action,uint256 legoId,address asset,address vault,uint256 amount,uint256 altLegoId,address altAsset,address altVault,uint256 altAmount,uint256 minAmountOut,address pool,bytes32 proof,address nftAddr,uint256 nftTokenId,int24 tickLower,int24 tickUpper,uint256 minAmountA,uint256 minAmountB,uint256 minLpAmount,uint256 liqToRemove,address recipient,bool isWethToEthConversion,SwapInstruction[] swapInstructions)')

MAX_INSTRUCTIONS: constant(uint256) = 20
MAX_SWAP_INSTRUCTIONS: constant(uint256) = 5
MAX_TOKEN_PATH: constant(uint256) = 5
API_VERSION: constant(String[28]) = "0.0.2"


@deploy
def __init__(
    _owner: address,
    _addyRegistry: address,
    _minOwnerChangeDelay: uint256,
    _maxOwnerChangeDelay: uint256,
):
    """
    @notice Initializes the Agent contract with owner and registry settings
    @dev Sets up the initial ownership and registry configuration for the agent
    @param _owner The address that will own the agent
    @param _addyRegistry The address of the registry contract
    @param _minOwnerChangeDelay The minimum delay required for owner changes
    @param _maxOwnerChangeDelay The maximum delay allowed for owner changes
    """
    assert empty(address) not in [_owner, _addyRegistry] # dev: invalid addrs
    own.__init__(_owner, _addyRegistry, _minOwnerChangeDelay, _maxOwnerChangeDelay)


@pure
@external
def apiVersion() -> String[28]:
    return API_VERSION


###########
# Deposit #
###########


@nonreentrant
@external
def depositTokens(
    _userWallet: address,
    _legoId: uint256,
    _asset: address,
    _vault: address,
    _amount: uint256 = max_value(uint256),
    _sig: Signature = empty(Signature),
) -> (uint256, address, uint256, uint256):
    owner: address = own.owner
    if msg.sender != owner:
        self._isValidSignature(abi_encode(DEPOSIT_TYPE_HASH, _userWallet, _legoId, _asset, _vault, _amount, _sig.expiration), _sig)
        assert _sig.signer == owner # dev: invalid signer
    return extcall UserWalletInterface(_userWallet).depositTokens(_legoId, _asset, _vault, _amount)


############
# Withdraw #
############


@nonreentrant
@external
def withdrawTokens(
    _userWallet: address,
    _legoId: uint256,
    _asset: address,
    _vaultAddr: address,
    _withdrawAmount: uint256 = max_value(uint256),
    _hasVaultToken: bool = True,
    _sig: Signature = empty(Signature),
) -> (uint256, uint256, uint256):
    owner: address = own.owner
    if msg.sender != owner:
        self._isValidSignature(abi_encode(WITHDRAWAL_TYPE_HASH, _userWallet, _legoId, _asset, _vaultAddr, _withdrawAmount, _hasVaultToken, _sig.expiration), _sig)
        assert _sig.signer == owner # dev: invalid signer
    return extcall UserWalletInterface(_userWallet).withdrawTokens(_legoId, _asset, _vaultAddr, _withdrawAmount, _hasVaultToken)


#############
# Rebalance #
#############


@nonreentrant
@external
def rebalance(
    _userWallet: address,
    _fromLegoId: uint256,
    _fromAsset: address,
    _fromVaultAddr: address,
    _toLegoId: uint256,
    _toVaultAddr: address,
    _fromVaultAmount: uint256 = max_value(uint256),
    _hasFromVaultToken: bool = True,
    _sig: Signature = empty(Signature),
) -> (uint256, address, uint256, uint256):
    owner: address = own.owner
    if msg.sender != owner:
        self._isValidSignature(abi_encode(REBALANCE_TYPE_HASH, _userWallet, _fromLegoId, _fromAsset, _fromVaultAddr, _toLegoId, _toVaultAddr, _fromVaultAmount, _hasFromVaultToken, _sig.expiration), _sig)
        assert _sig.signer == owner # dev: invalid signer
    return extcall UserWalletInterface(_userWallet).rebalance(_fromLegoId, _fromAsset, _fromVaultAddr, _toLegoId, _toVaultAddr, _fromVaultAmount, _hasFromVaultToken)


########
# Swap #
########


@nonreentrant
@external
def swapTokens(
    _userWallet: address,
    _swapInstructions: DynArray[SwapInstruction, MAX_SWAP_INSTRUCTIONS],
    _sig: Signature = empty(Signature),
) -> (uint256, uint256, uint256):
    owner: address = own.owner
    if msg.sender != owner:
        self._isValidSwapSignature(self._hashSwapInstructions(_userWallet, _swapInstructions, _sig.expiration), _sig)
        assert _sig.signer == owner # dev: invalid signer
    return extcall UserWalletCustom(_userWallet).swapTokens(_swapInstructions)


@view
@internal
def _encodeSwapInstruction(_instruction: SwapInstruction) -> Bytes[544]:
    # Just encode, no hash
    return abi_encode(
        SWAP_INSTRUCTION_TYPE_HASH,
        _instruction.legoId,
        _instruction.amountIn,
        _instruction.minAmountOut,
        _instruction.tokenPath,
        _instruction.poolPath
    )


@view
@internal
def _encodeSwapInstructions(_swapInstructions: DynArray[SwapInstruction, MAX_SWAP_INSTRUCTIONS]) -> Bytes[2720]:
    concatenated: Bytes[2720] = empty(Bytes[2720]) # max size for 5 instructions - 5*544
    for i: uint256 in range(len(_swapInstructions), bound=MAX_SWAP_INSTRUCTIONS):
        concatenated = convert(
            concat(
                concatenated, 
                self._encodeSwapInstruction(_swapInstructions[i])
            ),
            Bytes[2720]
        )
    return concatenated


@view
@internal
def _hashSwapInstructions(
    _userWallet: address,
    _swapInstructions: DynArray[SwapInstruction, MAX_SWAP_INSTRUCTIONS],
    _expiration: uint256,
) -> Bytes[2880]:
    # Now we encode everything and hash only once at the end
    return abi_encode(
        SWAP_ACTION_TYPE_HASH,
        _userWallet,
        self._encodeSwapInstructions(_swapInstructions),
        _expiration
    )


@internal
def _isValidSwapSignature(_encodedValue: Bytes[2880], _sig: Signature):
    encoded_hash: bytes32 = keccak256(_encodedValue)
    domain_sep: bytes32 = self._domainSeparator()
    
    digest: bytes32 = keccak256(concat(b'\x19\x01', domain_sep, encoded_hash))
    
    assert not self.usedSignatures[_sig.signature] # dev: signature already used
    assert _sig.expiration >= block.timestamp # dev: signature expired
    
    # NOTE: signature is packed as r, s, v
    r: bytes32 = convert(slice(_sig.signature, 0, 32), bytes32)
    s: bytes32 = convert(slice(_sig.signature, 32, 32), bytes32)
    v: uint8 = convert(slice(_sig.signature, 64, 1), uint8)
    
    response: Bytes[32] = raw_call(
        ECRECOVER_PRECOMPILE,
        abi_encode(digest, v, r, s),
        max_outsize=32,
        is_static_call=True # This is a view function
    )
    
    assert len(response) == 32 # dev: invalid ecrecover response length
    assert abi_decode(response, address) == _sig.signer # dev: invalid signature
    self.usedSignatures[_sig.signature] = True


@view
@external
def getSwapActionHash(
    _userWallet: address,
    _swapInstructions: DynArray[SwapInstruction, MAX_SWAP_INSTRUCTIONS],
    _expiration: uint256,
) -> bytes32:
    encodedValue: Bytes[2880] = self._hashSwapInstructions(_userWallet, _swapInstructions, _expiration)
    encoded_hash: bytes32 = keccak256(encodedValue)
    return keccak256(concat(b'\x19\x01', self._domainSeparator(), encoded_hash))


##################
# Borrow + Repay #
##################


@nonreentrant
@external
def borrow(
    _userWallet: address,
    _legoId: uint256,
    _borrowAsset: address = empty(address),
    _amount: uint256 = max_value(uint256),
    _sig: Signature = empty(Signature),
) -> (address, uint256, uint256):
    owner: address = own.owner
    if msg.sender != owner:
        self._isValidSignature(abi_encode(BORROW_TYPE_HASH, _userWallet, _legoId, _borrowAsset, _amount, _sig.expiration), _sig)
        assert _sig.signer == owner # dev: invalid signer
    return extcall UserWalletInterface(_userWallet).borrow(_legoId, _borrowAsset, _amount)


@nonreentrant
@external
def repayDebt(
    _userWallet: address,
    _legoId: uint256,
    _paymentAsset: address,
    _paymentAmount: uint256 = max_value(uint256),
    _sig: Signature = empty(Signature),
) -> (address, uint256, uint256, uint256):
    owner: address = own.owner
    if msg.sender != owner:
        self._isValidSignature(abi_encode(REPAY_TYPE_HASH, _userWallet, _legoId, _paymentAsset, _paymentAmount, _sig.expiration), _sig)
        assert _sig.signer == owner # dev: invalid signer
    return extcall UserWalletInterface(_userWallet).repayDebt(_legoId, _paymentAsset, _paymentAmount)


#################
# Claim Rewards #
#################


@nonreentrant
@external
def claimRewards(
    _userWallet: address,
    _legoId: uint256,
    _market: address = empty(address),
    _rewardToken: address = empty(address),
    _rewardAmount: uint256 = max_value(uint256),
    _proof: bytes32 = empty(bytes32),
    _sig: Signature = empty(Signature),
):
    owner: address = own.owner
    if msg.sender != owner:
        self._isValidSignature(abi_encode(CLAIM_REWARDS_TYPE_HASH, _userWallet, _legoId, _market, _rewardToken, _rewardAmount, _proof, _sig.expiration), _sig)
        assert _sig.signer == owner # dev: invalid signer
    extcall UserWalletInterface(_userWallet).claimRewards(_legoId, _market, _rewardToken, _rewardAmount, _proof)


#################
# Add Liquidity #
#################


@nonreentrant
@external
def addLiquidity(
    _userWallet: address,
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
    _sig: Signature = empty(Signature),
) -> (uint256, uint256, uint256, uint256, uint256):
    owner: address = own.owner
    if msg.sender != owner:
        self._isValidSignature(abi_encode(ADD_LIQ_TYPE_HASH, _userWallet, _legoId, _nftAddr, _nftTokenId, _pool, _tokenA, _tokenB, _amountA, _amountB, _tickLower, _tickUpper, _minAmountA, _minAmountB, _minLpAmount, _sig.expiration), _sig)
        assert _sig.signer == owner # dev: invalid signer
    return extcall UserWalletInterface(_userWallet).addLiquidity(_legoId, _nftAddr, _nftTokenId, _pool, _tokenA, _tokenB, _amountA, _amountB, _tickLower, _tickUpper, _minAmountA, _minAmountB, _minLpAmount)


####################
# Remove Liquidity #
####################


@nonreentrant
@external
def removeLiquidity(
    _userWallet: address,
    _legoId: uint256,
    _nftAddr: address,
    _nftTokenId: uint256,
    _pool: address,
    _tokenA: address,
    _tokenB: address,
    _liqToRemove: uint256 = max_value(uint256),
    _minAmountA: uint256 = 0,
    _minAmountB: uint256 = 0,
    _sig: Signature = empty(Signature),
) -> (uint256, uint256, uint256, bool):
    owner: address = own.owner
    if msg.sender != owner:
        self._isValidSignature(abi_encode(REMOVE_LIQ_TYPE_HASH, _userWallet, _legoId, _nftAddr, _nftTokenId, _pool, _tokenA, _tokenB, _liqToRemove, _minAmountA, _minAmountB, _sig.expiration), _sig)
        assert _sig.signer == owner # dev: invalid signer
    return extcall UserWalletInterface(_userWallet).removeLiquidity(_legoId, _nftAddr, _nftTokenId, _pool, _tokenA, _tokenB, _liqToRemove, _minAmountA, _minAmountB)


##################
# Transfer Funds #
##################


@nonreentrant
@external
def transferFunds(
    _userWallet: address,
    _recipient: address,
    _amount: uint256 = max_value(uint256),
    _asset: address = empty(address),
    _sig: Signature = empty(Signature),
) -> (uint256, uint256):
    owner: address = own.owner
    if msg.sender != owner:
        self._isValidSignature(abi_encode(TRANSFER_TYPE_HASH, _userWallet, _recipient, _amount, _asset, _sig.expiration), _sig)
        assert _sig.signer == owner # dev: invalid signer
    return extcall UserWalletInterface(_userWallet).transferFunds(_recipient, _amount, _asset)


################
# Wrapped ETH #
################


# eth -> weth


@nonreentrant
@external
def convertEthToWeth(
    _userWallet: address,
    _amount: uint256 = max_value(uint256),
    _depositLegoId: uint256 = 0,
    _depositVault: address = empty(address),
    _sig: Signature = empty(Signature),
) -> (uint256, address, uint256):
    owner: address = own.owner
    if msg.sender != owner:
        self._isValidSignature(abi_encode(ETH_TO_WETH_TYPE_HASH, _userWallet, _amount, _depositLegoId, _depositVault, _sig.expiration), _sig)
        assert _sig.signer == owner # dev: invalid signer
    return extcall UserWalletInterface(_userWallet).convertEthToWeth(_amount, _depositLegoId, _depositVault)


# weth -> eth


@nonreentrant
@external
def convertWethToEth(
    _userWallet: address,
    _amount: uint256 = max_value(uint256),
    _recipient: address = empty(address),
    _withdrawLegoId: uint256 = 0,
    _withdrawVaultAddr: address = empty(address),
    _hasWithdrawVaultToken: bool = True,
    _sig: Signature = empty(Signature),
) -> uint256:
    owner: address = own.owner
    if msg.sender != owner:
        self._isValidSignature(abi_encode(WETH_TO_ETH_TYPE_HASH, _userWallet, _amount, _recipient, _withdrawLegoId, _withdrawVaultAddr, _hasWithdrawVaultToken, _sig.expiration), _sig)
        assert _sig.signer == owner # dev: invalid signer
    return extcall UserWalletInterface(_userWallet).convertWethToEth(_amount, _recipient, _withdrawLegoId, _withdrawVaultAddr, _hasWithdrawVaultToken)


#################
# Batch Actions #
#################


@nonreentrant
@external
def performBatchActions(
    _userWallet: address,
    _instructions: DynArray[ActionInstruction, MAX_INSTRUCTIONS],
    _sig: Signature = empty(Signature),
) -> bool:
    owner: address = own.owner
    if msg.sender != owner:
        self._isValidBatchSignature(self._hashBatchActions(_userWallet, _instructions, _sig.expiration), _sig)
        assert _sig.signer == owner # dev: invalid signer

    assert len(_instructions) != 0 # dev: no instructions
    prevAmountReceived: uint256 = 0

    # not using these vars
    naAddyA: address = empty(address)
    naValueA: uint256 = 0
    naValueB: uint256 = 0
    naValueC: uint256 = 0
    naValueD: uint256 = 0
    naBool: bool = False

    # iterate through instructions
    for j: uint256 in range(len(_instructions), bound=MAX_INSTRUCTIONS):
        i: ActionInstruction = _instructions[j]

        # deposit
        if i.action == ActionType.DEPOSIT:
            amount: uint256 = i.amount
            if i.usePrevAmountOut and prevAmountReceived != 0:
                amount = prevAmountReceived
            naValueA, naAddyA, prevAmountReceived, naValueB = extcall UserWalletInterface(_userWallet).depositTokens(i.legoId, i.asset, i.vault, amount)

        # withdraw
        elif i.action == ActionType.WITHDRAWAL:
            amount: uint256 = i.amount
            if i.usePrevAmountOut and prevAmountReceived != 0:
                amount = prevAmountReceived
            prevAmountReceived, naValueA, naValueB = extcall UserWalletInterface(_userWallet).withdrawTokens(i.legoId, i.asset, i.vault, amount, i.hasVaultToken)

        # rebalance
        elif i.action == ActionType.REBALANCE:
            amount: uint256 = i.amount
            if i.usePrevAmountOut and prevAmountReceived != 0:
                amount = prevAmountReceived
            naValueA, naAddyA, prevAmountReceived, naValueB = extcall UserWalletInterface(_userWallet).rebalance(i.legoId, i.asset, i.vault, i.altLegoId, i.altVault, amount, i.hasVaultToken)

        # swap
        elif i.action == ActionType.SWAP:
            if i.usePrevAmountOut and prevAmountReceived != 0:
                i.swapInstructions[0].amountIn = prevAmountReceived
            naValueA, prevAmountReceived, naValueB = extcall UserWalletCustom(_userWallet).swapTokens(i.swapInstructions)

        # borrow
        elif i.action == ActionType.BORROW:
            naAddyA, prevAmountReceived, naValueB = extcall UserWalletInterface(_userWallet).borrow(i.legoId, i.asset, i.amount)

        # repay debt
        elif i.action == ActionType.REPAY:
            amount: uint256 = i.amount
            if i.usePrevAmountOut and prevAmountReceived != 0:
                amount = prevAmountReceived
            extcall UserWalletInterface(_userWallet).repayDebt(i.legoId, i.asset, amount)
            prevAmountReceived = 0

        # claim rewards
        elif i.action == ActionType.CLAIM_REWARDS:
            extcall UserWalletInterface(_userWallet).claimRewards(i.legoId, i.asset, i.altAsset, i.amount, i.proof)
            prevAmountReceived = 0

        # add liquidity
        elif i.action == ActionType.ADD_LIQ:
            amount: uint256 = i.amount # this only goes towards token A amount
            if i.usePrevAmountOut and prevAmountReceived != 0:
                amount = prevAmountReceived
            prevAmountReceived, naValueA, naValueB, naValueC, naValueD = extcall UserWalletInterface(_userWallet).addLiquidity(i.legoId, i.nftAddr, i.nftTokenId, i.pool, i.asset, i.altAsset, amount, i.altAmount, i.tickLower, i.tickUpper, i.minAmountA, i.minAmountB, i.minLpAmount)

        # remove liquidity
        elif i.action == ActionType.REMOVE_LIQ:
            amount: uint256 = i.liqToRemove # this only goes to `_liqToRemove`
            if i.usePrevAmountOut and prevAmountReceived != 0:
                amount = prevAmountReceived
            naValueA, naValueB, naValueC, naBool = extcall UserWalletInterface(_userWallet).removeLiquidity(i.legoId, i.nftAddr, i.nftTokenId, i.pool, i.asset, i.altAsset, amount, i.minAmountA, i.minAmountB)
            prevAmountReceived = 0

        # transfer
        elif i.action == ActionType.TRANSFER:
            amount: uint256 = i.amount
            if i.usePrevAmountOut and prevAmountReceived != 0:
                amount = prevAmountReceived
            extcall UserWalletInterface(_userWallet).transferFunds(i.recipient, amount, i.asset)
            prevAmountReceived = 0

        # conversion
        elif i.action == ActionType.CONVERSION:
            amount: uint256 = i.amount
            if i.usePrevAmountOut and prevAmountReceived != 0:
                amount = prevAmountReceived
            if i.isWethToEthConversion:
                prevAmountReceived = extcall UserWalletInterface(_userWallet).convertWethToEth(amount, i.recipient, i.legoId, i.vault, i.hasVaultToken)
            else:
                prevAmountReceived, naAddyA, naValueB = extcall UserWalletInterface(_userWallet).convertEthToWeth(amount, i.legoId, i.vault)
                if naValueB != 0:
                    prevAmountReceived = naValueB

    return True


@view
@internal
def _encodeBatchActionInstruction(_instr: ActionInstruction) -> Bytes[3584]:
    encodedSwapInstructions: Bytes[2720] = self._encodeSwapInstructions(_instr.swapInstructions)

    # Just encode, no hash
    return abi_encode(
        ACTION_INSTRUCTION_TYPE_HASH,
        _instr.usePrevAmountOut,
        _instr.action,
        _instr.legoId,
        _instr.asset,
        _instr.vault,
        _instr.amount,
        _instr.altLegoId,
        _instr.altAsset,
        _instr.altVault,
        _instr.altAmount,
        _instr.minAmountOut,
        _instr.pool,
        _instr.proof,
        _instr.nftAddr,
        _instr.nftTokenId,
        _instr.tickLower,
        _instr.tickUpper,
        _instr.minAmountA,
        _instr.minAmountB,
        _instr.minLpAmount,
        _instr.liqToRemove,
        _instr.recipient,
        _instr.isWethToEthConversion,
        encodedSwapInstructions,
        _instr.hasVaultToken,
    )


@view
@internal
def _encodeBatchInstructions(_instructions: DynArray[ActionInstruction, MAX_INSTRUCTIONS]) -> Bytes[15360]:
    concatenated: Bytes[15360] = empty(Bytes[15360]) # max size for 20 instructions - 20*768
    for i: uint256 in range(len(_instructions), bound=MAX_INSTRUCTIONS):
        concatenated = convert(
            concat(
                concatenated, 
                self._encodeBatchActionInstruction(_instructions[i])
            ),
            Bytes[15360]
        )
    return concatenated


@view
@internal
def _hashBatchActions(_userWallet: address, _instructions: DynArray[ActionInstruction, MAX_INSTRUCTIONS], _expiration: uint256) -> Bytes[15520]:
    # Now we encode everything and hash only once at the end
    return abi_encode(
        BATCH_ACTIONS_TYPE_HASH,
        _userWallet,
        self._encodeBatchInstructions(_instructions),
        _expiration
    )


@internal
def _isValidBatchSignature(_encodedValue: Bytes[15520], _sig: Signature):
    encoded_hash: bytes32 = keccak256(_encodedValue)
    domain_sep: bytes32 = self._domainSeparator()
    
    digest: bytes32 = keccak256(concat(b'\x19\x01', domain_sep, encoded_hash))
    
    assert not self.usedSignatures[_sig.signature] # dev: signature already used
    assert _sig.expiration >= block.timestamp # dev: signature expired
    
    # NOTE: signature is packed as r, s, v
    r: bytes32 = convert(slice(_sig.signature, 0, 32), bytes32)
    s: bytes32 = convert(slice(_sig.signature, 32, 32), bytes32)
    v: uint8 = convert(slice(_sig.signature, 64, 1), uint8)
    
    response: Bytes[32] = raw_call(
        ECRECOVER_PRECOMPILE,
        abi_encode(digest, v, r, s),
        max_outsize=32,
        is_static_call=True # This is a view function
    )
    
    assert len(response) == 32 # dev: invalid ecrecover response length
    assert abi_decode(response, address) == _sig.signer # dev: invalid signature
    self.usedSignatures[_sig.signature] = True


@view
@external
def getBatchActionHash(_userWallet: address, _instructions: DynArray[ActionInstruction, MAX_INSTRUCTIONS], _expiration: uint256) -> bytes32:
    encodedValue: Bytes[15520] = self._hashBatchActions(_userWallet, _instructions, _expiration)
    encoded_hash: bytes32 = keccak256(encodedValue)
    return keccak256(concat(b'\x19\x01', self._domainSeparator(), encoded_hash))


###########
# EIP 712 #
###########


@view
@external
def DOMAIN_SEPARATOR() -> bytes32:
    return self._domainSeparator()


@view
@internal
def _domainSeparator() -> bytes32:
    return keccak256(
        concat(
            DOMAIN_TYPE_HASH,
            keccak256('UnderscoreAgent'),
            keccak256(API_VERSION),
            abi_encode(chain.id, self)
        )
    )


@internal
def _isValidSignature(_encodedValue: Bytes[512], _sig: Signature):
    assert not self.usedSignatures[_sig.signature] # dev: signature already used
    assert _sig.expiration >= block.timestamp # dev: signature expired
    
    digest: bytes32 = keccak256(concat(b'\x19\x01', self._domainSeparator(), keccak256(_encodedValue)))

    # NOTE: signature is packed as r, s, v
    r: bytes32 = convert(slice(_sig.signature, 0, 32), bytes32)
    s: bytes32 = convert(slice(_sig.signature, 32, 32), bytes32)
    v: uint8 = convert(slice(_sig.signature, 64, 1), uint8)
    
    response: Bytes[32] = raw_call(
        ECRECOVER_PRECOMPILE,
        abi_encode(digest, v, r, s),
        max_outsize=32,
        is_static_call=True # This is a view function
    )
    
    assert len(response) == 32 # dev: invalid ecrecover response length
    assert abi_decode(response, address) == _sig.signer # dev: invalid signature
    self.usedSignatures[_sig.signature] = True


#################
# Recover Funds #
#################


@external
def recoverFunds(_asset: address) -> bool:
    """
    @notice Transfers funds from the agent wallet to the owner
    @dev Only callable by the owner
    @param _asset The address of the asset to recover
    @return bool True if the funds were recovered successfully, False if no funds to recover
    """
    owner: address = own.owner
    assert msg.sender == owner # dev: no perms
    balance: uint256 = staticcall IERC20(_asset).balanceOf(self)
    if empty(address) in [owner, _asset] or balance == 0:
        return False

    assert extcall IERC20(_asset).transfer(owner, balance, default_return_value=True) # dev: recovery failed
    log AgentFundsRecovered(asset=_asset, recipient=owner, balance=balance)
    return True
