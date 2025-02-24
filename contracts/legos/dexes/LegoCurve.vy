# @version 0.4.0
# pragma optimize codesize

implements: LegoDex
initializes: gov
exports: gov.__interface__

import contracts.modules.Governable as gov
from ethereum.ercs import IERC20
from interfaces import LegoDex

interface CurveMetaRegistry:
    def get_coin_indices(_pool: address, _from: address, _to: address) -> (int128, int128, bool): view
    def find_pools_for_coins(_from: address, _to: address) -> DynArray[address, MAX_POOLS]: view
    def get_registry_handlers_from_pool(_pool: address) -> address[10]: view
    def get_base_registry(_addr: address) -> address: view
    def get_balances(_pool: address) -> uint256[8]: view
    def get_coins(_pool: address) -> address[8]: view
    def get_n_coins(_pool: address) -> uint256: view
    def get_lp_token(_pool: address) -> address: view
    def is_registered(_pool: address) -> bool: view
    def is_meta(_pool: address) -> bool: view

interface TwoCryptoPool:
    def remove_liquidity_one_coin(_lpBurnAmount: uint256, _index: uint256, _minAmountOut: uint256, _useEth: bool = False, _recipient: address = msg.sender) -> uint256: nonpayable
    def exchange(_i: uint256, _j: uint256, _dx: uint256, _min_dy: uint256, _use_eth: bool = False, _receiver: address = msg.sender) -> uint256: payable
    def remove_liquidity(_lpBurnAmount: uint256, _minAmountsOut: uint256[2], _useEth: bool = False, _recipient: address = msg.sender): nonpayable
    def add_liquidity(_amounts: uint256[2], _minLpAmount: uint256, _useEth: bool = False, _recipient: address = msg.sender) -> uint256: payable

interface TwoCryptoNgPool:
    def remove_liquidity_one_coin(_lpBurnAmount: uint256, _index: uint256, _minAmountOut: uint256, _recipient: address = msg.sender) -> uint256: nonpayable
    def remove_liquidity(_lpBurnAmount: uint256, _minAmountsOut: uint256[2], _recipient: address = msg.sender) -> uint256[2]: nonpayable
    def exchange(i: uint256, j: uint256, dx: uint256, min_dy: uint256, receiver: address = msg.sender) -> uint256: nonpayable
    def add_liquidity(_amounts: uint256[2], _minLpAmount: uint256, _recipient: address = msg.sender) -> uint256: nonpayable

interface StableNgTwo:
    def remove_liquidity(_lpBurnAmount: uint256, _minAmountsOut: DynArray[uint256, 2], _recipient: address = msg.sender, _claimAdminFees: bool = True) -> DynArray[uint256, 2]: nonpayable
    def remove_liquidity_one_coin(_lpBurnAmount: uint256, _index: int128, _minAmountOut: uint256, _recipient: address = msg.sender) -> uint256: nonpayable
    def add_liquidity(_amounts: DynArray[uint256, 2], _minLpAmount: uint256, _recipient: address = msg.sender) -> uint256: nonpayable

interface TriCryptoPool:
    def remove_liquidity(_lpBurnAmount: uint256, _minAmountsOut: uint256[3], _useEth: bool = False, _recipient: address = msg.sender, _claimAdminFees: bool = True) -> uint256[3]: nonpayable
    def remove_liquidity_one_coin(_lpBurnAmount: uint256, _index: uint256, _minAmountOut: uint256, _useEth: bool = False, _recipient: address = msg.sender) -> uint256: nonpayable
    def add_liquidity(_amounts: uint256[3], _minLpAmount: uint256, _useEth: bool = False, _recipient: address = msg.sender) -> uint256: payable

interface MetaPoolTwo:
    def remove_liquidity(_lpBurnAmount: uint256, _minAmountsOut: uint256[2], _recipient: address = msg.sender) -> uint256[2]: nonpayable
    def add_liquidity(_amounts: uint256[2], _minLpAmount: uint256, _recipient: address = msg.sender) -> uint256: nonpayable

interface MetaPoolThree:
    def remove_liquidity(_lpBurnAmount: uint256, _minAmountsOut: uint256[3], _recipient: address = msg.sender) -> uint256[3]: nonpayable
    def add_liquidity(_amounts: uint256[3], _minLpAmount: uint256, _recipient: address = msg.sender) -> uint256: nonpayable

interface MetaPoolFour:
    def remove_liquidity(_lpBurnAmount: uint256, _minAmountsOut: uint256[4], _recipient: address = msg.sender) -> uint256[4]: nonpayable
    def add_liquidity(_amounts: uint256[4], _minLpAmount: uint256, _recipient: address = msg.sender) -> uint256: nonpayable

interface MetaPoolCommon:
    def remove_liquidity_one_coin(_lpBurnAmount: uint256, _index: int128, _minAmountOut: uint256, _recipient: address = msg.sender) -> uint256: nonpayable

interface StableNgThree:
    def add_liquidity(_amounts: DynArray[uint256, 3], _minLpAmount: uint256, _recipient: address = msg.sender) -> uint256: nonpayable

interface StableNgFour:
    def add_liquidity(_amounts: DynArray[uint256, 4], _minLpAmount: uint256, _recipient: address = msg.sender) -> uint256: nonpayable

interface CommonCurvePool:
    def exchange(_i: int128, _j: int128, _dx: uint256, _min_dy: uint256, _receiver: address = msg.sender) -> uint256: nonpayable

interface CryptoLegacyPool:
    def exchange(_i: uint256, _j: uint256, _dx: uint256, _min_dy: uint256, _use_eth: bool = False) -> uint256: payable

interface OracleRegistry:
    def getUsdValue(_asset: address, _amount: uint256, _shouldRaise: bool = False) -> uint256: view

interface CurveAddressProvider:
    def get_address(_id: uint256) -> address: view

interface AddyRegistry:
    def getAddy(_addyId: uint256) -> address: view

flag PoolType:
    STABLESWAP_NG
    TWO_CRYPTO_NG
    TRICRYPTO_NG
    TWO_CRYPTO
    METAPOOL
    CRYPTO

struct PoolData:
    pool: address
    indexTokenA: uint256
    indexTokenB: uint256
    poolType: PoolType
    numCoins: uint256

struct CurveRegistries:
    StableSwapNg: address
    TwoCryptoNg: address
    TricryptoNg: address
    TwoCrypto: address
    MetaPool: address

event CurveSwap:
    sender: indexed(address)
    tokenIn: indexed(address)
    tokenOut: indexed(address)
    amountIn: uint256
    amountOut: uint256
    usdValue: uint256
    recipient: address

event CurveLiquidityAdded:
    sender: indexed(address)
    tokenA: indexed(address)
    tokenB: indexed(address)
    amountA: uint256
    amountB: uint256
    lpAmountReceived: uint256
    usdValue: uint256
    recipient: address

event CurveLiquidityRemoved:
    sender: address
    pool: indexed(address)
    tokenA: indexed(address)
    tokenB: indexed(address)
    amountA: uint256
    amountB: uint256
    lpToken: address
    lpAmountBurned: uint256
    usdValue: uint256
    recipient: address

event FundsRecovered:
    asset: indexed(address)
    recipient: indexed(address)
    balance: uint256

event PreferredPoolsSet:
    numPools: uint256

event CurveLegoIdSet:
    legoId: uint256

event CurveActivated:
    isActivated: bool

preferredPools: public(DynArray[address, MAX_POOLS])

# config
legoId: public(uint256)
isActivated: public(bool)
ADDY_REGISTRY: public(immutable(address))

CURVE_META_REGISTRY: public(immutable(address))
CURVE_REGISTRIES: public(immutable(CurveRegistries))

# curve ids
METAPOOL_FACTORY_ID: constant(uint256) = 3 # 0x3093f9B57A428F3EB6285a589cb35bEA6e78c336
TWO_CRYPTO_FACTORY_ID: constant(uint256) = 6 # 0x5EF72230578b3e399E6C6F4F6360edF95e83BBfd
META_REGISTRY_ID: constant(uint256) = 7 # 0x87DD13Dd25a1DBde0E1EdcF5B8Fa6cfff7eABCaD
TRICRYPTO_NG_FACTORY_ID: constant(uint256) = 11 # 0xA5961898870943c68037F6848d2D866Ed2016bcB
STABLESWAP_NG_FACTORY_ID: constant(uint256) = 12 # 0xd2002373543Ce3527023C75e7518C274A51ce712
TWO_CRYPTO_NG_FACTORY_ID: constant(uint256) = 13 # 0xc9Fe0C63Af9A39402e8a5514f9c43Af0322b665F

MAX_POOLS: constant(uint256) = 50


@deploy
def __init__(_curveAddressProvider: address, _addyRegistry: address):
    assert empty(address) not in [_curveAddressProvider, _addyRegistry] # dev: invalid addrs
    ADDY_REGISTRY = _addyRegistry
    self.isActivated = True
    gov.__init__(_addyRegistry)

    CURVE_META_REGISTRY = staticcall CurveAddressProvider(_curveAddressProvider).get_address(META_REGISTRY_ID)
    CURVE_REGISTRIES = CurveRegistries(
        StableSwapNg= staticcall CurveAddressProvider(_curveAddressProvider).get_address(STABLESWAP_NG_FACTORY_ID),
        TwoCryptoNg= staticcall CurveAddressProvider(_curveAddressProvider).get_address(TWO_CRYPTO_NG_FACTORY_ID),
        TricryptoNg= staticcall CurveAddressProvider(_curveAddressProvider).get_address(TRICRYPTO_NG_FACTORY_ID),
        TwoCrypto= staticcall CurveAddressProvider(_curveAddressProvider).get_address(TWO_CRYPTO_FACTORY_ID),
        MetaPool= staticcall CurveAddressProvider(_curveAddressProvider).get_address(METAPOOL_FACTORY_ID),
    )


@view
@external
def getRegistries() -> DynArray[address, 10]:
    return [CURVE_META_REGISTRY]


@view
@internal
def _getUsdValue(
    _tokenA: address,
    _amountA: uint256,
    _tokenB: address,
    _amountB: uint256,
    _isSwap: bool,
    _oracleRegistry: address,
) -> uint256:
    oracleRegistry: address = _oracleRegistry
    if _oracleRegistry == empty(address):
        oracleRegistry = staticcall AddyRegistry(ADDY_REGISTRY).getAddy(4)
    usdValueA: uint256 = 0
    if _tokenA != empty(address) and _amountA != 0:
        usdValueA = staticcall OracleRegistry(oracleRegistry).getUsdValue(_tokenA, _amountA)
    usdValueB: uint256 = 0
    if _tokenB != empty(address) and _amountB != 0:
        usdValueB = staticcall OracleRegistry(oracleRegistry).getUsdValue(_tokenB, _amountB)
    if _isSwap:
        return max(usdValueA, usdValueB)
    else:
        return usdValueA + usdValueB


@view
@external
def getLpToken(_pool: address) -> address:
    return staticcall CurveMetaRegistry(CURVE_META_REGISTRY).get_lp_token(_pool)


########
# Swap #
########


@external
def swapTokens(
    _tokenIn: address,
    _tokenOut: address,
    _amountIn: uint256,
    _minAmountOut: uint256,
    _pool: address,
    _recipient: address,
    _oracleRegistry: address = empty(address),
) -> (uint256, uint256, uint256, uint256):
    assert self.isActivated # dev: not activated

    assert empty(address) not in [_tokenIn, _tokenOut] # dev: invalid tokens
    assert _tokenIn != _tokenOut # dev: invalid tokens

    # get pool data
    p: PoolData = empty(PoolData)
    if _pool != empty(address):
        p = self._getPoolData(_pool, _tokenIn, _tokenOut, CURVE_META_REGISTRY)
    else:
        p = self._findBestPool(_tokenIn, _tokenOut, CURVE_META_REGISTRY)

    # pre balances
    preLegoBalance: uint256 = staticcall IERC20(_tokenIn).balanceOf(self)

    # transfer deposit asset to this contract
    transferAmount: uint256 = min(_amountIn, staticcall IERC20(_tokenIn).balanceOf(msg.sender))
    assert transferAmount != 0 # dev: nothing to transfer
    assert extcall IERC20(_tokenIn).transferFrom(msg.sender, self, transferAmount, default_return_value=True) # dev: transfer failed
    swapAmount: uint256 = min(transferAmount, staticcall IERC20(_tokenIn).balanceOf(self))

    # swap assets via lego partner
    toAmount: uint256 = self._swapTokensInPool(p, _tokenIn, _tokenOut, swapAmount, _minAmountOut, _recipient)

    # refund if full swap didn't get through
    currentLegoBalance: uint256 = staticcall IERC20(_tokenIn).balanceOf(self)
    refundAssetAmount: uint256 = 0
    if currentLegoBalance > preLegoBalance:
        refundAssetAmount = currentLegoBalance - preLegoBalance
        assert extcall IERC20(_tokenIn).transfer(msg.sender, refundAssetAmount, default_return_value=True) # dev: transfer failed
        swapAmount -= refundAssetAmount

    usdValue: uint256 = self._getUsdValue(_tokenIn, swapAmount, _tokenOut, toAmount, True, _oracleRegistry)
    log CurveSwap(msg.sender, _tokenIn, _tokenOut, swapAmount, toAmount, usdValue, _recipient)
    return swapAmount, toAmount, refundAssetAmount, usdValue


# swap in pool


@internal
def _swapTokensInPool(
    _p: PoolData,
    _tokenIn: address,
    _tokenOut: address,
    _amountIn: uint256,
    _minAmountOut: uint256,
    _recipient: address,
) -> uint256:
    toAmount: uint256 = 0

    # approve token in
    assert extcall IERC20(_tokenIn).approve(_p.pool, _amountIn, default_return_value=True) # dev: approval failed

    # stable ng
    if _p.poolType == PoolType.STABLESWAP_NG:
        toAmount = extcall CommonCurvePool(_p.pool).exchange(convert(_p.indexTokenA, int128), convert(_p.indexTokenB, int128), _amountIn, _minAmountOut, _recipient)

    # two crypto ng
    elif _p.poolType == PoolType.TWO_CRYPTO_NG:
        toAmount = extcall TwoCryptoNgPool(_p.pool).exchange(_p.indexTokenA, _p.indexTokenB, _amountIn, _minAmountOut, _recipient)

    # two crypto + tricrypto ng pools
    elif _p.poolType == PoolType.TRICRYPTO_NG or _p.poolType == PoolType.TWO_CRYPTO:
        toAmount = extcall TwoCryptoPool(_p.pool).exchange(_p.indexTokenA, _p.indexTokenB, _amountIn, _minAmountOut, False, _recipient)

    # meta pools
    elif _p.poolType == PoolType.METAPOOL:
        if staticcall CurveMetaRegistry(CURVE_META_REGISTRY).is_meta(_p.pool):
            raise "Not Implemented"
        else:
            toAmount = extcall CommonCurvePool(_p.pool).exchange(convert(_p.indexTokenA, int128), convert(_p.indexTokenB, int128), _amountIn, _minAmountOut, _recipient)

    # crypto v1
    else:
        toAmount = extcall CryptoLegacyPool(_p.pool).exchange(_p.indexTokenA, _p.indexTokenB, _amountIn, _minAmountOut, False)
        assert extcall IERC20(_tokenOut).transfer(_recipient, toAmount, default_return_value=True) # dev: transfer failed

    # reset approvals
    assert extcall IERC20(_tokenIn).approve(_p.pool, 0, default_return_value=True) # dev: approval failed

    assert toAmount != 0 # dev: no tokens swapped
    return toAmount


#################
# Add Liquidity #
#################


@external
def addLiquidity(
    _nftTokenId: uint256,
    _pool: address,
    _tokenA: address,
    _tokenB: address,
    _tickLower: int24,
    _tickUpper: int24,
    _amountA: uint256,
    _amountB: uint256,
    _minAmountA: uint256,
    _minAmountB: uint256,
    _minLpAmount: uint256,
    _recipient: address,
    _oracleRegistry: address = empty(address),
) -> (uint256, uint256, uint256, uint256, uint256, uint256, uint256):
    assert self.isActivated # dev: not activated

    assert empty(address) not in [_tokenA, _tokenB] # dev: invalid tokens
    assert _tokenA != _tokenB # dev: invalid tokens

    # pre balances
    preLegoBalanceA: uint256 = staticcall IERC20(_tokenA).balanceOf(self)
    preLegoBalanceB: uint256 = staticcall IERC20(_tokenB).balanceOf(self)

    # token a
    liqAmountA: uint256 = min(_amountA, staticcall IERC20(_tokenA).balanceOf(msg.sender))
    if liqAmountA != 0:
        assert extcall IERC20(_tokenA).transferFrom(msg.sender, self, liqAmountA, default_return_value=True) # dev: transfer failed
        liqAmountA = min(liqAmountA, staticcall IERC20(_tokenA).balanceOf(self))
        assert extcall IERC20(_tokenA).approve(_pool, liqAmountA, default_return_value=True) # dev: approval failed

    # token b
    liqAmountB: uint256 = min(_amountB, staticcall IERC20(_tokenB).balanceOf(msg.sender))
    if liqAmountB != 0:
        assert extcall IERC20(_tokenB).transferFrom(msg.sender, self, liqAmountB, default_return_value=True) # dev: transfer failed
        liqAmountB = min(liqAmountB, staticcall IERC20(_tokenB).balanceOf(self))
        assert extcall IERC20(_tokenB).approve(_pool, liqAmountB, default_return_value=True) # dev: approval failed

    assert liqAmountA != 0 or liqAmountB != 0 # dev: need at least one token amount

    # pool data
    metaRegistry: address = CURVE_META_REGISTRY
    p: PoolData = self._getPoolData(_pool, _tokenA, _tokenB, metaRegistry)

    # add liquidity
    lpAmountReceived: uint256 = 0
    if p.poolType == PoolType.STABLESWAP_NG:
        lpAmountReceived = self._addLiquidityStableNg(p, liqAmountA, liqAmountB, _minLpAmount, _recipient)
    elif p.poolType == PoolType.TWO_CRYPTO_NG:
        lpAmountReceived = self._addLiquidityTwoCryptoNg(p, liqAmountA, liqAmountB, _minLpAmount, _recipient)
    elif p.poolType == PoolType.TWO_CRYPTO:
        lpAmountReceived = self._addLiquidityTwoCrypto(p, liqAmountA, liqAmountB, _minLpAmount, _recipient)
    elif p.poolType == PoolType.TRICRYPTO_NG:
        lpAmountReceived = self._addLiquidityTricrypto(p, liqAmountA, liqAmountB, _minLpAmount, _recipient)
    elif p.poolType == PoolType.METAPOOL:
        if staticcall CurveMetaRegistry(metaRegistry).is_meta(p.pool):
            raise "metapool: not implemented" # will need zap contracts for this
        else:
            lpAmountReceived = self._addLiquidityMetaPool(p, liqAmountA, liqAmountB, _minLpAmount, _recipient)
    else:
        raise "crypto v1: not implemented" # don't think any of these are deployed on L2s
    assert lpAmountReceived != 0 # dev: no liquidity added

    # handle token a refunds / approvals
    refundAssetAmountA: uint256 = 0
    if liqAmountA != 0:
        assert extcall IERC20(_tokenA).approve(_pool, 0, default_return_value=True) # dev: approval failed

        currentLegoBalanceA: uint256 = staticcall IERC20(_tokenA).balanceOf(self)
        if currentLegoBalanceA > preLegoBalanceA:
            refundAssetAmountA = currentLegoBalanceA - preLegoBalanceA
            assert extcall IERC20(_tokenA).transfer(msg.sender, refundAssetAmountA, default_return_value=True) # dev: transfer failed
            liqAmountA -= refundAssetAmountA

    # handle token b refunds / approvals
    refundAssetAmountB: uint256 = 0
    if liqAmountB != 0:
        assert extcall IERC20(_tokenB).approve(_pool, 0, default_return_value=True) # dev: approval failed

        currentLegoBalanceB: uint256 = staticcall IERC20(_tokenB).balanceOf(self)
        if currentLegoBalanceB > preLegoBalanceB:
            refundAssetAmountB = currentLegoBalanceB - preLegoBalanceB
            assert extcall IERC20(_tokenB).transfer(msg.sender, refundAssetAmountB, default_return_value=True) # dev: transfer failed
            liqAmountB -= refundAssetAmountB

    usdValue: uint256 = self._getUsdValue(_tokenA, liqAmountA, _tokenB, liqAmountB, False, _oracleRegistry)
    log CurveLiquidityAdded(msg.sender, _tokenA, _tokenB, liqAmountA, liqAmountB, lpAmountReceived, usdValue, _recipient)
    return lpAmountReceived, liqAmountA, liqAmountB, usdValue, refundAssetAmountA, refundAssetAmountB, 0


@internal
def _addLiquidityStableNg(
    _p: PoolData,
    _liqAmountA: uint256,
    _liqAmountB: uint256,
    _minLpAmount: uint256,
    _recipient: address,
) -> uint256:
    lpAmountReceived: uint256 = 0

    if _p.numCoins == 2:
        amounts: DynArray[uint256, 2] = [0, 0]
        if _liqAmountA != 0:
            amounts[_p.indexTokenA] = _liqAmountA
        if _liqAmountB != 0:
            amounts[_p.indexTokenB] = _liqAmountB
        lpAmountReceived = extcall StableNgTwo(_p.pool).add_liquidity(amounts, _minLpAmount, _recipient)

    elif _p.numCoins == 3:
        amounts: DynArray[uint256, 3] = [0, 0, 0]
        if _liqAmountA != 0:
            amounts[_p.indexTokenA] = _liqAmountA
        if _liqAmountB != 0:
            amounts[_p.indexTokenB] = _liqAmountB
        lpAmountReceived = extcall StableNgThree(_p.pool).add_liquidity(amounts, _minLpAmount, _recipient)

    elif _p.numCoins == 4:
        amounts: DynArray[uint256, 4] = [0, 0, 0, 0]
        if _liqAmountA != 0:
            amounts[_p.indexTokenA] = _liqAmountA
        if _liqAmountB != 0:
            amounts[_p.indexTokenB] = _liqAmountB
        lpAmountReceived = extcall StableNgFour(_p.pool).add_liquidity(amounts, _minLpAmount, _recipient)

    return lpAmountReceived


@internal
def _addLiquidityTwoCryptoNg(
    _p: PoolData,
    _liqAmountA: uint256,
    _liqAmountB: uint256,
    _minLpAmount: uint256,
    _recipient: address,
) -> uint256:
    amounts: uint256[2] = [0, 0]
    if _liqAmountA != 0:
        amounts[_p.indexTokenA] = _liqAmountA
    if _liqAmountB != 0:
        amounts[_p.indexTokenB] = _liqAmountB
    return extcall TwoCryptoNgPool(_p.pool).add_liquidity(amounts, _minLpAmount, _recipient)


@internal
def _addLiquidityTwoCrypto(
    _p: PoolData,
    _liqAmountA: uint256,
    _liqAmountB: uint256,
    _minLpAmount: uint256,
    _recipient: address,
) -> uint256:
    amounts: uint256[2] = [0, 0]
    if _liqAmountA != 0:
        amounts[_p.indexTokenA] = _liqAmountA
    if _liqAmountB != 0:
        amounts[_p.indexTokenB] = _liqAmountB
    return extcall TwoCryptoPool(_p.pool).add_liquidity(amounts, _minLpAmount, False, _recipient)


@internal
def _addLiquidityTricrypto(
    _p: PoolData,
    _liqAmountA: uint256,
    _liqAmountB: uint256,
    _minLpAmount: uint256,
    _recipient: address,
) -> uint256:
    amounts: uint256[3] = [0, 0, 0]
    if _liqAmountA != 0:
        amounts[_p.indexTokenA] = _liqAmountA
    if _liqAmountB != 0:
        amounts[_p.indexTokenB] = _liqAmountB
    return extcall TriCryptoPool(_p.pool).add_liquidity(amounts, _minLpAmount, False, _recipient)


@internal
def _addLiquidityMetaPool(
    _p: PoolData,
    _liqAmountA: uint256,
    _liqAmountB: uint256,
    _minLpAmount: uint256,
    _recipient: address,
) -> uint256:
    lpAmountReceived: uint256 = 0

    if _p.numCoins == 2:
        amounts: uint256[2] = [0, 0]
        if _liqAmountA != 0:
            amounts[_p.indexTokenA] = _liqAmountA
        if _liqAmountB != 0:
            amounts[_p.indexTokenB] = _liqAmountB
        lpAmountReceived = extcall MetaPoolTwo(_p.pool).add_liquidity(amounts, _minLpAmount, _recipient)

    elif _p.numCoins == 3:
        amounts: uint256[3] = [0, 0, 0]
        if _liqAmountA != 0:
            amounts[_p.indexTokenA] = _liqAmountA
        if _liqAmountB != 0:
            amounts[_p.indexTokenB] = _liqAmountB
        lpAmountReceived = extcall MetaPoolThree(_p.pool).add_liquidity(amounts, _minLpAmount, _recipient)

    elif _p.numCoins == 4:
        amounts: uint256[4] = [0, 0, 0, 0]
        if _liqAmountA != 0:
            amounts[_p.indexTokenA] = _liqAmountA
        if _liqAmountB != 0:
            amounts[_p.indexTokenB] = _liqAmountB
        lpAmountReceived = extcall MetaPoolFour(_p.pool).add_liquidity(amounts, _minLpAmount, _recipient)

    return lpAmountReceived


####################
# Remove Liquidity #
####################


@external
def removeLiquidity(
    _nftTokenId: uint256,
    _pool: address,
    _tokenA: address,
    _tokenB: address,
    _lpToken: address,
    _liqToRemove: uint256,
    _minAmountA: uint256,
    _minAmountB: uint256,
    _recipient: address,
    _oracleRegistry: address = empty(address),
) -> (uint256, uint256, uint256, uint256, uint256, bool):
    assert self.isActivated # dev: not activated

    # if one of the tokens is empty, it means they only want to remove liquidity for one token
    assert _tokenA != empty(address) or _tokenB != empty(address) # dev: invalid tokens
    assert _tokenA != _tokenB # dev: invalid tokens

    isEmptyTokenA: bool = _tokenA == empty(address)
    isOneCoinRemoval: bool = isEmptyTokenA or _tokenB == empty(address)

    # pre balance
    preLegoBalance: uint256 = staticcall IERC20(_lpToken).balanceOf(self)

    # lp token amount
    lpAmount: uint256 = min(_liqToRemove, staticcall IERC20(_lpToken).balanceOf(msg.sender))
    assert lpAmount != 0 # dev: nothing to transfer
    assert extcall IERC20(_lpToken).transferFrom(msg.sender, self, lpAmount, default_return_value=True) # dev: transfer failed
    lpAmount = min(lpAmount, staticcall IERC20(_lpToken).balanceOf(self))

    # approvals
    assert extcall IERC20(_lpToken).approve(_pool, lpAmount, default_return_value=True) # dev: approval failed

    # pool data
    metaRegistry: address = CURVE_META_REGISTRY
    p: PoolData = self._getPoolData(_pool, _tokenA, _tokenB, metaRegistry)

    # remove liquidity
    amountA: uint256 = 0
    amountB: uint256 = 0
    if p.poolType == PoolType.STABLESWAP_NG:
        if isOneCoinRemoval:
            amountA, amountB = self._removeLiquidityStableNgOneCoin(p, isEmptyTokenA, lpAmount, _minAmountA, _minAmountB, _recipient)
        else:
            amountA, amountB = self._removeLiquidityStableNg(p, lpAmount, _minAmountA, _minAmountB, _recipient)
    elif p.poolType == PoolType.TWO_CRYPTO_NG:
        if isOneCoinRemoval:
            amountA, amountB = self._removeLiquidityTwoCryptoNgOneCoin(p, isEmptyTokenA, lpAmount, _minAmountA, _minAmountB, _recipient)
        else:
            amountA, amountB = self._removeLiquidityTwoCryptoNg(p, lpAmount, _minAmountA, _minAmountB, _recipient)
    elif p.poolType == PoolType.TWO_CRYPTO:
        if isOneCoinRemoval:
            amountA, amountB = self._removeLiquidityTwoCryptoOneCoin(p, isEmptyTokenA, lpAmount, _minAmountA, _minAmountB, _recipient)
        else:
            amountA, amountB = self._removeLiquidityTwoCrypto(p, lpAmount, _tokenA, _tokenB, _minAmountA, _minAmountB, _recipient)
    elif p.poolType == PoolType.TRICRYPTO_NG:
        if isOneCoinRemoval:
            amountA, amountB = self._removeLiquidityTricryptoOneCoin(p, isEmptyTokenA, lpAmount, _minAmountA, _minAmountB, _recipient)
        else:
            amountA, amountB = self._removeLiquidityTricrypto(p, lpAmount, _minAmountA, _minAmountB, _recipient)
    elif p.poolType == PoolType.METAPOOL:
        if staticcall CurveMetaRegistry(metaRegistry).is_meta(p.pool):
            raise "metapool: not implemented" # will need zap contracts for this
        else:
            if isOneCoinRemoval:
                amountA, amountB = self._removeLiquidityMetaPoolOneCoin(p, isEmptyTokenA, lpAmount, _minAmountA, _minAmountB, _recipient)
            else:
                amountA, amountB = self._removeLiquidityMetaPool(p, lpAmount, _minAmountA, _minAmountB, _recipient)
    else:
        raise "crypto v1: not implemented" # don't think any of these are deployed on L2s

    assert amountA != 0 or amountB != 0 # dev: nothing removed

    # reset approvals
    assert extcall IERC20(_lpToken).approve(_pool, 0, default_return_value=True) # dev: approval failed

    # refund if full liquidity was not removed
    currentLegoBalance: uint256 = staticcall IERC20(_lpToken).balanceOf(self)
    refundedLpAmount: uint256 = 0
    if currentLegoBalance > preLegoBalance:
        refundedLpAmount = currentLegoBalance - preLegoBalance
        assert extcall IERC20(_lpToken).transfer(msg.sender, refundedLpAmount, default_return_value=True) # dev: transfer failed
        lpAmount -= refundedLpAmount

    usdValue: uint256 = self._getUsdValue(_tokenA, amountA, _tokenB, amountB, False, _oracleRegistry)
    log CurveLiquidityRemoved(msg.sender, _pool, _tokenA, _tokenB, amountA, amountB, _lpToken, lpAmount, usdValue, _recipient)
    return amountA, amountB, usdValue, lpAmount, refundedLpAmount, refundedLpAmount != 0


# stable ng


@internal
def _removeLiquidityStableNgOneCoin(
    _p: PoolData,
    _isEmptyTokenA: bool,
    _lpAmount: uint256,
    _minAmountA: uint256,
    _minAmountB: uint256,
    _recipient: address,
) -> (uint256, uint256):
    tokenIndex: uint256 = 0
    minAmountOut: uint256 = 0
    tokenIndex, minAmountOut = self._getTokenIndexAndMinAmountOut(_isEmptyTokenA, _p.indexTokenA, _p.indexTokenB, _minAmountA, _minAmountB)
    amountOut: uint256 = extcall StableNgTwo(_p.pool).remove_liquidity_one_coin(_lpAmount, convert(tokenIndex, int128), minAmountOut, _recipient)
    return self._getTokenAmounts(_isEmptyTokenA, amountOut)


@internal
def _removeLiquidityStableNg(
    _p: PoolData,
    _lpAmount: uint256,
    _minAmountA: uint256,
    _minAmountB: uint256,
    _recipient: address,
) -> (uint256, uint256):

    # only supporting 2-coin pools, can't give minAmountsOut for other coins
    assert _p.numCoins == 2 # dev: invalid pool

    minAmountsOut: DynArray[uint256, 2] = [0, 0]
    minAmountsOut[_p.indexTokenA] = _minAmountA
    minAmountsOut[_p.indexTokenB] = _minAmountB

    # remove liquidity
    amountsOut: DynArray[uint256, 2] = extcall StableNgTwo(_p.pool).remove_liquidity(_lpAmount, minAmountsOut, _recipient, False)
    return amountsOut[_p.indexTokenA], amountsOut[_p.indexTokenB]


# two crypto ng


@internal
def _removeLiquidityTwoCryptoNgOneCoin(
    _p: PoolData,
    _isEmptyTokenA: bool,
    _lpAmount: uint256,
    _minAmountA: uint256,
    _minAmountB: uint256,
    _recipient: address,
) -> (uint256, uint256):
    tokenIndex: uint256 = 0
    minAmountOut: uint256 = 0
    tokenIndex, minAmountOut = self._getTokenIndexAndMinAmountOut(_isEmptyTokenA, _p.indexTokenA, _p.indexTokenB, _minAmountA, _minAmountB)
    amountOut: uint256 = extcall TwoCryptoNgPool(_p.pool).remove_liquidity_one_coin(_lpAmount, tokenIndex, minAmountOut, _recipient)
    return self._getTokenAmounts(_isEmptyTokenA, amountOut)


@internal
def _removeLiquidityTwoCryptoNg(
    _p: PoolData,
    _lpAmount: uint256,
    _minAmountA: uint256,
    _minAmountB: uint256,
    _recipient: address,
) -> (uint256, uint256):

    # only supporting 2-coin pools, can't give minAmountsOut for other coins
    assert _p.numCoins == 2 # dev: invalid pool

    minAmountsOut: uint256[2] = [0, 0]
    minAmountsOut[_p.indexTokenA] = _minAmountA
    minAmountsOut[_p.indexTokenB] = _minAmountB

    # remove liquidity
    amountsOut: uint256[2] = extcall TwoCryptoNgPool(_p.pool).remove_liquidity(_lpAmount, minAmountsOut, _recipient)
    return amountsOut[_p.indexTokenA], amountsOut[_p.indexTokenB]


# two crypto


@internal
def _removeLiquidityTwoCryptoOneCoin(
    _p: PoolData,
    _isEmptyTokenA: bool,
    _lpAmount: uint256,
    _minAmountA: uint256,
    _minAmountB: uint256,
    _recipient: address,
) -> (uint256, uint256):
    tokenIndex: uint256 = 0
    minAmountOut: uint256 = 0
    tokenIndex, minAmountOut = self._getTokenIndexAndMinAmountOut(_isEmptyTokenA, _p.indexTokenA, _p.indexTokenB, _minAmountA, _minAmountB)
    amountOut: uint256 = extcall TwoCryptoPool(_p.pool).remove_liquidity_one_coin(_lpAmount, tokenIndex, minAmountOut, False, _recipient)
    return self._getTokenAmounts(_isEmptyTokenA, amountOut)


@internal
def _removeLiquidityTwoCrypto(
    _p: PoolData,
    _lpAmount: uint256,
    _tokenA: address,
    _tokenB: address,
    _minAmountA: uint256,
    _minAmountB: uint256,
    _recipient: address,
) -> (uint256, uint256):

    # only supporting 2-coin pools
    assert _p.numCoins == 2 # dev: invalid pool

    # pre balances
    preBalTokenA: uint256 = staticcall IERC20(_tokenA).balanceOf(_recipient)
    preBalTokenB: uint256 = staticcall IERC20(_tokenB).balanceOf(_recipient)

    # organize min amounts out
    minAmountsOut: uint256[2] = [0, 0]
    minAmountsOut[_p.indexTokenA] = _minAmountA
    minAmountsOut[_p.indexTokenB] = _minAmountB

    # remove liquidity
    extcall TwoCryptoPool(_p.pool).remove_liquidity(_lpAmount, minAmountsOut, False, _recipient)

    # get amounts
    amountA: uint256 = 0
    postBalTokenA: uint256 = staticcall IERC20(_tokenA).balanceOf(_recipient)
    if postBalTokenA > preBalTokenA:
        amountA = postBalTokenA - preBalTokenA

    amountB: uint256 = 0
    postBalTokenB: uint256 = staticcall IERC20(_tokenB).balanceOf(_recipient)
    if postBalTokenB > preBalTokenB:
        amountB = postBalTokenB - preBalTokenB

    return amountA, amountB


# tricrypto ng


@internal
def _removeLiquidityTricryptoOneCoin(
    _p: PoolData,
    _isEmptyTokenA: bool,
    _lpAmount: uint256,
    _minAmountA: uint256,
    _minAmountB: uint256,
    _recipient: address,
) -> (uint256, uint256):
    tokenIndex: uint256 = 0
    minAmountOut: uint256 = 0
    tokenIndex, minAmountOut = self._getTokenIndexAndMinAmountOut(_isEmptyTokenA, _p.indexTokenA, _p.indexTokenB, _minAmountA, _minAmountB)
    amountOut: uint256 = extcall TriCryptoPool(_p.pool).remove_liquidity_one_coin(_lpAmount, tokenIndex, minAmountOut, False, _recipient)
    return self._getTokenAmounts(_isEmptyTokenA, amountOut)


@internal
def _removeLiquidityTricrypto(
    _p: PoolData,
    _lpAmount: uint256,
    _minAmountA: uint256,
    _minAmountB: uint256,
    _recipient: address,
) -> (uint256, uint256):
    minAmountsOut: uint256[3] = [0, 0, 0]
    minAmountsOut[_p.indexTokenA] = _minAmountA
    minAmountsOut[_p.indexTokenB] = _minAmountB

    # NOTE: user can only specify two min amounts out, the third will be set to zero

    # remove liquidity
    amountsOut: uint256[3] = extcall TriCryptoPool(_p.pool).remove_liquidity(_lpAmount, minAmountsOut, False, _recipient, False)
    return amountsOut[_p.indexTokenA], amountsOut[_p.indexTokenB]


# meta pool


@internal
def _removeLiquidityMetaPoolOneCoin(
    _p: PoolData,
    _isEmptyTokenA: bool,
    _lpAmount: uint256,
    _minAmountA: uint256,
    _minAmountB: uint256,
    _recipient: address,
) -> (uint256, uint256):
    tokenIndex: uint256 = 0
    minAmountOut: uint256 = 0
    tokenIndex, minAmountOut = self._getTokenIndexAndMinAmountOut(_isEmptyTokenA, _p.indexTokenA, _p.indexTokenB, _minAmountA, _minAmountB)
    amountOut: uint256 = extcall MetaPoolCommon(_p.pool).remove_liquidity_one_coin(_lpAmount, convert(tokenIndex, int128), minAmountOut, _recipient)
    return self._getTokenAmounts(_isEmptyTokenA, amountOut)


@internal
def _removeLiquidityMetaPool(
    _p: PoolData,
    _lpAmount: uint256,
    _minAmountA: uint256,
    _minAmountB: uint256,
    _recipient: address,
) -> (uint256, uint256):
    amountA: uint256 = 0
    amountB: uint256 = 0

    # NOTE: user can only specify two min amounts out, the third/fourth will be set to zero

    if _p.numCoins == 2:
        minAmountsOut: uint256[2] = [0, 0]
        minAmountsOut[_p.indexTokenA] = _minAmountA
        minAmountsOut[_p.indexTokenB] = _minAmountB
        amountsOut: uint256[2] = extcall MetaPoolTwo(_p.pool).remove_liquidity(_lpAmount, minAmountsOut, _recipient)
        amountA = amountsOut[_p.indexTokenA]
        amountB = amountsOut[_p.indexTokenB]

    elif _p.numCoins == 3:
        minAmountsOut: uint256[3] = [0, 0, 0]
        minAmountsOut[_p.indexTokenA] = _minAmountA
        minAmountsOut[_p.indexTokenB] = _minAmountB
        amountsOut: uint256[3] = extcall MetaPoolThree(_p.pool).remove_liquidity(_lpAmount, minAmountsOut, _recipient)
        amountA = amountsOut[_p.indexTokenA]
        amountB = amountsOut[_p.indexTokenB]

    elif _p.numCoins == 4:
        minAmountsOut: uint256[4] = [0, 0, 0, 0]
        minAmountsOut[_p.indexTokenA] = _minAmountA
        minAmountsOut[_p.indexTokenB] = _minAmountB
        amountsOut: uint256[4] = extcall MetaPoolFour(_p.pool).remove_liquidity(_lpAmount, minAmountsOut, _recipient)
        amountA = amountsOut[_p.indexTokenA]
        amountB = amountsOut[_p.indexTokenB]

    else:
        raise "meta pool: pools beyond 4-coin are not supported"

    return amountA, amountB


# utils


@pure
@internal
def _getTokenIndexAndMinAmountOut(
    _isEmptyTokenA: bool,
    _indexTokenA: uint256,
    _indexTokenB: uint256,
    _minAmountA: uint256,
    _minAmountB: uint256,
) -> (uint256, uint256):
    tokenIndex: uint256 = _indexTokenA
    minAmountOut: uint256 = _minAmountA
    if _isEmptyTokenA:
        tokenIndex = _indexTokenB
        minAmountOut = _minAmountB
    return tokenIndex, minAmountOut


@pure
@internal
def _getTokenAmounts(_isEmptyTokenA: bool, _amountOut: uint256) -> (uint256, uint256):
    amountA: uint256 = 0
    amountB: uint256 = 0
    if _isEmptyTokenA:
        amountB = _amountOut
    else:
        amountA = _amountOut
    return amountA, amountB


#############
# Pool Data #
#############


@view
@external
def findBestPool(_tokenIn: address, _tokenOut: address) -> PoolData:
    return self._findBestPool(_tokenIn, _tokenOut, CURVE_META_REGISTRY)


@view
@internal
def _findBestPool(_tokenIn: address, _tokenOut: address, _metaRegistry: address) -> PoolData:
    bestLiquidity: uint256 = 0
    bestPoolData: PoolData = empty(PoolData)

    pools: DynArray[address, MAX_POOLS] = staticcall CurveMetaRegistry(_metaRegistry).find_pools_for_coins(_tokenIn, _tokenOut)
    assert len(pools) != 0 # dev: no pools found

    preferredPools: DynArray[address, MAX_POOLS] = self.preferredPools
    for i: uint256 in range(len(pools), bound=MAX_POOLS):
        pool: address = pools[i]
        if pool == empty(address):
            continue

        na: bool = False
        indexTokenA: int128 = 0
        indexTokenB: int128 = 0

        # check if pool is preferred
        if pool in preferredPools:
            indexTokenA, indexTokenB, na = staticcall CurveMetaRegistry(_metaRegistry).get_coin_indices(pool, _tokenIn, _tokenOut)
            bestPoolData = PoolData(pool=pool, indexTokenA=convert(indexTokenA, uint256), indexTokenB=convert(indexTokenB, uint256), poolType=empty(PoolType), numCoins=0)
            break

        # balances
        balances: uint256[8] = staticcall CurveMetaRegistry(_metaRegistry).get_balances(pool)
        if balances[0] == 0:
            continue

        # token indexes 
        indexTokenA, indexTokenB, na = staticcall CurveMetaRegistry(_metaRegistry).get_coin_indices(pool, _tokenIn, _tokenOut)
        
        # compare liquidity
        liquidity: uint256 = balances[indexTokenA] + balances[indexTokenB]
        if liquidity > bestLiquidity:
            bestLiquidity = liquidity
            bestPoolData = PoolData(pool=pool, indexTokenA=convert(indexTokenA, uint256), indexTokenB=convert(indexTokenB, uint256), poolType=empty(PoolType), numCoins=0)

    assert bestPoolData.pool != empty(address) # dev: no pool found
    bestPoolData.poolType = self._getPoolType(bestPoolData.pool, _metaRegistry)
    bestPoolData.numCoins = staticcall CurveMetaRegistry(_metaRegistry).get_n_coins(bestPoolData.pool)
    return bestPoolData


@view
@external
def getPoolData(_pool: address, _tokenA: address, _tokenB: address) -> PoolData:
    return self._getPoolData(_pool, _tokenA, _tokenB, CURVE_META_REGISTRY)


@view
@internal
def _getPoolData(_pool: address, _tokenA: address, _tokenB: address, _metaRegistry: address) -> PoolData:
    coins: address[8] = staticcall CurveMetaRegistry(_metaRegistry).get_coins(_pool)
    
    # validate tokens
    if _tokenA != empty(address):
        assert _tokenA in coins # dev: invalid tokens
    if _tokenB != empty(address):
        assert _tokenB in coins # dev: invalid tokens

    # get indices
    indexTokenA: uint256 = max_value(uint256)
    indexTokenB: uint256 = max_value(uint256)
    numCoins: uint256 = 0
    for coin: address in coins:
        if coin == empty(address):
            break
        if coin == _tokenA:
            indexTokenA = numCoins
        elif coin == _tokenB:
            indexTokenB = numCoins
        numCoins += 1

    return PoolData(
        pool=_pool,
        indexTokenA=indexTokenA,
        indexTokenB=indexTokenB,
        poolType=self._getPoolType(_pool, _metaRegistry),
        numCoins=numCoins,
    )


@view
@internal
def _getPoolType(_pool: address, _metaRegistry: address) -> PoolType:
    # check what type of pool this is based on where it's registered on Curve
    registryHandlers: address[10] = staticcall CurveMetaRegistry(_metaRegistry).get_registry_handlers_from_pool(_pool)
    baseRegistry: address = staticcall CurveMetaRegistry(_metaRegistry).get_base_registry(registryHandlers[0])

    curveRegistries: CurveRegistries = CURVE_REGISTRIES
    poolType: PoolType = empty(PoolType)
    if baseRegistry == curveRegistries.StableSwapNg:
        poolType = PoolType.STABLESWAP_NG
    elif baseRegistry == curveRegistries.TwoCryptoNg:
        poolType = PoolType.TWO_CRYPTO_NG
    elif baseRegistry == curveRegistries.TricryptoNg:
        poolType = PoolType.TRICRYPTO_NG
    elif baseRegistry == curveRegistries.TwoCrypto:
        poolType = PoolType.TWO_CRYPTO
    elif baseRegistry == curveRegistries.MetaPool:
        poolType = PoolType.METAPOOL
    else:
        poolType = PoolType.CRYPTO
    return poolType


###################
# Preferred Pools #
###################


@external
def setPreferredPools(_pools: DynArray[address, MAX_POOLS]) -> bool:
    assert gov._isGovernor(msg.sender) # dev: no perms

    pools: DynArray[address, MAX_POOLS] = []
    for i: uint256 in range(len(_pools), bound=MAX_POOLS):
        p: address = _pools[i]
        if p == empty(address):
            continue
        if p not in pools and staticcall CurveMetaRegistry(CURVE_META_REGISTRY).is_registered(p):
            pools.append(p)

    self.preferredPools = pools
    log PreferredPoolsSet(len(pools))
    return True


#################
# Recover Funds #
#################


@external
def recoverFunds(_asset: address, _recipient: address) -> bool:
    assert gov._isGovernor(msg.sender) # dev: no perms

    balance: uint256 = staticcall IERC20(_asset).balanceOf(self)
    if empty(address) in [_recipient, _asset] or balance == 0:
        return False

    assert extcall IERC20(_asset).transfer(_recipient, balance, default_return_value=True) # dev: recovery failed
    log FundsRecovered(_asset, _recipient, balance)
    return True


###########
# Lego Id #
###########


@external
def setLegoId(_legoId: uint256) -> bool:
    assert msg.sender == staticcall AddyRegistry(ADDY_REGISTRY).getAddy(2) # dev: no perms
    prevLegoId: uint256 = self.legoId
    assert prevLegoId == 0 or prevLegoId == _legoId # dev: invalid lego id
    self.legoId = _legoId
    log CurveLegoIdSet(_legoId)
    return True


@external
def activate(_shouldActivate: bool):
    assert gov._isGovernor(msg.sender) # dev: no perms
    self.isActivated = _shouldActivate
    log CurveActivated(_shouldActivate)