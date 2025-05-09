# SPDX-License-Identifier: BUSL-1.1
# Underscore Protocol License: https://github.com/underscore-finance/underscore/blob/main/licenses/BUSL_LICENSE
# Underscore Protocol (C) 2025 Hightop Financial, Inc.
# @version 0.4.1

implements: OraclePartner
initializes: gov
initializes: oad
exports: gov.__interface__
exports: oad.__interface__

import contracts.modules.LocalGov as gov
import contracts.modules.OracleAssetData as oad
import interfaces.OraclePartnerInterface as OraclePartner

interface ChainlinkFeed:
    def latestRoundData() -> ChainlinkRound: view
    def decimals() -> uint8: view 

interface AddyRegistry:
    def getAddy(_addyId: uint256) -> address: view

struct ChainlinkRound:
    roundId: uint80
    answer: int256
    startedAt: uint256
    updatedAt: uint256
    answeredInRound: uint80

struct ChainlinkConfig:
    feed: address
    decimals: uint256
    needsEthToUsd: bool
    needsBtcToUsd: bool

event ChainlinkFeedAdded:
    asset: indexed(address)
    chainlinkFeed: indexed(address)
    needsEthToUsd: bool
    needsBtcToUsd: bool

event ChainlinkFeedDisabled:
    asset: indexed(address)

# chainlink config
feedConfig: public(HashMap[address, ChainlinkConfig])

# general config
oraclePartnerId: public(uint256)
ADDY_REGISTRY: public(immutable(address))

# default assets
WETH: public(immutable(address))
ETH: public(immutable(address))
BTC: public(immutable(address))

NORMALIZED_DECIMALS: constant(uint256) = 18


@deploy
def __init__(
    _wethAddr: address,
    _ethAddr: address,
    _btcAddr: address,
    _ethUsdFeed: address,
    _btcUsdFeed: address,
    _addyRegistry: address,
):
    assert empty(address) not in [_wethAddr, _ethAddr, _btcAddr, _addyRegistry] # dev: invalid addrs
    ADDY_REGISTRY = _addyRegistry
    gov.__init__(empty(address), _addyRegistry, 0, 0)
    oad.__init__()

    # set default assets
    WETH = _wethAddr
    ETH = _ethAddr
    BTC = _btcAddr

    # set default feeds
    if _ethUsdFeed != empty(address):
        assert self._setChainlinkFeed(ETH, _ethUsdFeed, False, False)
        assert self._setChainlinkFeed(WETH, _ethUsdFeed, False, False)
    if _btcUsdFeed != empty(address):
        assert self._setChainlinkFeed(BTC, _btcUsdFeed, False, False)


#############
# Get Price #
#############


@view
@external
def getPrice(_asset: address, _staleTime: uint256 = 0, _oracleRegistry: address = empty(address)) -> uint256:
    config: ChainlinkConfig = self.feedConfig[_asset]
    if config.feed == empty(address):
        return 0
    return self._getPrice(config.feed, config.decimals, config.needsEthToUsd, config.needsBtcToUsd, _staleTime)


@view
@external
def getPriceAndHasFeed(_asset: address, _staleTime: uint256 = 0, _oracleRegistry: address = empty(address)) -> (uint256, bool):
    config: ChainlinkConfig = self.feedConfig[_asset]
    if config.feed == empty(address):
        return 0, False
    return self._getPrice(config.feed, config.decimals, config.needsEthToUsd, config.needsBtcToUsd, _staleTime), True


@view
@internal
def _getPrice(
    _feed: address, 
    _decimals: uint256,
    _needsEthToUsd: bool,
    _needsBtcToUsd: bool,
    _staleTime: uint256,
) -> uint256:
    price: uint256 = self._getChainlinkData(_feed, _decimals, _staleTime)
    if price == 0:
        return 0

    # if price needs ETH -> USD conversion
    if _needsEthToUsd:
        ethConfig: ChainlinkConfig = self.feedConfig[ETH]
        ethUsdPrice: uint256 = self._getChainlinkData(ethConfig.feed, ethConfig.decimals, _staleTime)
        price = price * ethUsdPrice // (10 ** NORMALIZED_DECIMALS)

    # if price needs BTC -> USD conversion
    elif _needsBtcToUsd:
        btcConfig: ChainlinkConfig = self.feedConfig[BTC]
        btcUsdPrice: uint256 = self._getChainlinkData(btcConfig.feed, btcConfig.decimals, _staleTime)
        price = price * btcUsdPrice // (10 ** NORMALIZED_DECIMALS)

    return price


@view
@external
def getChainlinkData(_feed: address, _decimals: uint256, _staleTime: uint256 = 0) -> uint256:
    return self._getChainlinkData(_feed, _decimals, _staleTime)


@view
@internal
def _getChainlinkData(_feed: address, _decimals: uint256, _staleTime: uint256) -> uint256:
    oracle: ChainlinkRound = staticcall ChainlinkFeed(_feed).latestRoundData()

    # NOTE: choosing to fail gracefully in Underscore

    # oracle has no price
    if oracle.answer <= 0:
        return 0

    # bad decimals
    if _decimals > NORMALIZED_DECIMALS:
        return 0

    # price is too stale
    if _staleTime != 0 and block.timestamp - oracle.updatedAt > _staleTime:
        return 0

    # handle decimal normalization
    price: uint256 = convert(oracle.answer, uint256)
    decimals: uint256 = _decimals
    if decimals < NORMALIZED_DECIMALS:
        decimals = NORMALIZED_DECIMALS - decimals
        price = price * (10 ** decimals)

    return price


@view
@external
def hasPriceFeed(_asset: address) -> bool:
    return self._hasPriceFeed(_asset)


@view
@internal
def _hasPriceFeed(_asset: address) -> bool:
    return self.feedConfig[_asset].feed != empty(address)


#####################
# Config Price Feed #
#####################


# set price feed


@view
@external
def isValidChainlinkFeed(
    _asset: address, 
    _feed: address,
    _needsEthToUsd: bool,
    _needsBtcToUsd: bool,
) -> bool:
    decimals: uint256 = convert(staticcall ChainlinkFeed(_feed).decimals(), uint256)
    return self._isValidChainlinkFeed(_asset, _feed, decimals, _needsEthToUsd, _needsBtcToUsd)


@view
@internal
def _isValidChainlinkFeed(
    _asset: address, 
    _feed: address,
    _decimals: uint256,
    _needsEthToUsd: bool,
    _needsBtcToUsd: bool,
) -> bool:
    if empty(address) in [_asset, _feed]:
        return False
    if _needsEthToUsd and _needsBtcToUsd:
        return False
    return self._getPrice(_feed, _decimals, _needsEthToUsd, _needsBtcToUsd, 0) != 0


@external
def setChainlinkFeed(
    _asset: address, 
    _feed: address, 
    _needsEthToUsd: bool = False,
    _needsBtcToUsd: bool = False,
) -> bool:
    assert gov._canGovern(msg.sender) # dev: no perms
    return self._setChainlinkFeed(_asset, _feed, _needsEthToUsd, _needsBtcToUsd)


@internal
def _setChainlinkFeed(
    _asset: address, 
    _feed: address, 
    _needsEthToUsd: bool = False,
    _needsBtcToUsd: bool = False,
) -> bool:
    decimals: uint256 = convert(staticcall ChainlinkFeed(_feed).decimals(), uint256)
    if not self._isValidChainlinkFeed(_asset, _feed, decimals, _needsEthToUsd, _needsBtcToUsd):
        return False

    self.feedConfig[_asset] = ChainlinkConfig(
        feed=_feed,
        decimals=decimals,
        needsEthToUsd=_needsEthToUsd,
        needsBtcToUsd=_needsBtcToUsd,
    )
    oad._addAsset(_asset)
    log ChainlinkFeedAdded(asset=_asset, chainlinkFeed=_feed, needsEthToUsd=_needsEthToUsd, needsBtcToUsd=_needsBtcToUsd)
    return True


# disable price feed


@external
def disableChainlinkPriceFeed(_asset: address) -> bool:
    assert gov._canGovern(msg.sender) # dev: no perms
    assert _asset not in [ETH, WETH, BTC] # dev: cannot disable default feeds
    if not self._hasPriceFeed(_asset):
        return False
    self.feedConfig[_asset] = empty(ChainlinkConfig)
    oad._removeAsset(_asset)
    log ChainlinkFeedDisabled(asset=_asset)
    return True


##########
# Config #
##########


@external
def setOraclePartnerId(_oracleId: uint256) -> bool:
    assert msg.sender == staticcall AddyRegistry(ADDY_REGISTRY).getAddy(4) # dev: no perms
    prevId: uint256 = self.oraclePartnerId
    assert prevId == 0 or prevId == _oracleId # dev: invalid oracle id
    self.oraclePartnerId = _oracleId
    return True
