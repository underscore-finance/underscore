# @version 0.4.0

implements: LegoYield

from ethereum.ercs import IERC20
from interfaces import LegoYield

interface Erc4626Interface:
    def redeem(_vaultTokenAmount: uint256, _recipient: address, _owner: address) -> uint256: nonpayable
    def deposit(_assetAmount: uint256, _recipient: address) -> uint256: nonpayable
    def convertToAssets(_vaultTokenAmount: uint256) -> uint256: view
    def totalAssets() -> uint256: view
    def asset() -> address: view

interface AddyRegistry:
    def getAddy(_addyId: uint256) -> address: view
    def governor() -> address: view

interface OracleRegistry:
    def getUsdValue(_asset: address, _amount: uint256, _shouldRaise: bool = False) -> uint256: view

interface FluidLendingResolver:
    def getAllFTokens() -> DynArray[address, MAX_FTOKENS]: view

event FluidDeposit:
    sender: indexed(address)
    asset: indexed(address)
    vaultToken: indexed(address)
    assetAmountDeposited: uint256
    usdValue: uint256
    vaultTokenAmountReceived: uint256
    recipient: address

event FluidWithdrawal:
    sender: indexed(address)
    asset: indexed(address)
    vaultToken: indexed(address)
    assetAmountReceived: uint256
    usdValue: uint256
    vaultTokenAmountBurned: uint256
    recipient: address

event AssetOpportunityAdded:
    asset: indexed(address)
    vaultToken: indexed(address)

event AssetOpportunityRemoved:
    asset: indexed(address)
    vaultToken: indexed(address)

event FundsRecovered:
    asset: indexed(address)
    recipient: indexed(address)
    balance: uint256

event FluidLegoIdSet:
    legoId: uint256

event FluidActivated:
    isActivated: bool

# asset opportunities
assetOpportunities: public(HashMap[address, HashMap[uint256, address]]) # asset -> index -> vault token
indexOfAssetOpportunity: public(HashMap[address, HashMap[address, uint256]]) # asset -> vault token -> index
numAssetOpportunities: public(HashMap[address, uint256]) # asset -> number of opportunities
vaultToAsset: public(HashMap[address, address]) # vault token -> asset

# assets
assets: public(HashMap[uint256, address]) # index -> asset
indexOfAsset: public(HashMap[address, uint256]) # asset -> index
numAssets: public(uint256) # number of assets

# config
legoId: public(uint256)
isActivated: public(bool)
FLUID_RESOLVER: public(immutable(address))
ADDY_REGISTRY: public(immutable(address))

MAX_FTOKENS: constant(uint256) = 50
MAX_VAULTS: constant(uint256) = 15
MAX_ASSETS: constant(uint256) = 25


@deploy
def __init__(_fluidResolver: address, _addyRegistry: address):
    assert empty(address) not in [_fluidResolver, _addyRegistry] # dev: invalid addrs
    FLUID_RESOLVER = _fluidResolver
    ADDY_REGISTRY = _addyRegistry
    self.isActivated = True


@view
@external
def getRegistries() -> DynArray[address, 10]:
    return [FLUID_RESOLVER]


#############
# Utilities #
#############


# assets and vault tokens


@view
@external
def getAssetOpportunities(_asset: address) -> DynArray[address, MAX_VAULTS]:
    numOpportunities: uint256 = self.numAssetOpportunities[_asset]
    if numOpportunities == 0:
        return []
    opportunities: DynArray[address, MAX_VAULTS] = []
    for i: uint256 in range(1, numOpportunities, bound=MAX_VAULTS):
        opportunities.append(self.assetOpportunities[_asset][i])
    return opportunities


@view
@external
def getAssets() -> DynArray[address, MAX_ASSETS]:
    numAssets: uint256 = self.numAssets
    if numAssets == 0:
        return []
    assets: DynArray[address, MAX_ASSETS] = []
    for i: uint256 in range(1, numAssets, bound=MAX_ASSETS):
        assets.append(self.assets[i])
    return assets


# underlying asset


@view
@external
def isVaultToken(_vaultToken: address) -> bool:
    return self._isVaultToken(_vaultToken)


@view
@internal
def _isVaultToken(_vaultToken: address) -> bool:
    if self.vaultToAsset[_vaultToken] != empty(address):
        return True
    return self._isValidFToken(_vaultToken)


@view
@internal
def _isValidFToken(_fToken: address) -> bool:
    fTokens: DynArray[address, MAX_FTOKENS] = staticcall FluidLendingResolver(FLUID_RESOLVER).getAllFTokens()
    return _fToken in fTokens


@view
@external
def getUnderlyingAsset(_vaultToken: address) -> address:
    return self._getUnderlyingAsset(_vaultToken)


@view
@internal
def _getUnderlyingAsset(_vaultToken: address) -> address:
    asset: address = self.vaultToAsset[_vaultToken]
    if asset == empty(address) and self._isValidFToken(_vaultToken):
        asset = staticcall Erc4626Interface(_vaultToken).asset()
    return asset


# underlying amount


@view
@external
def getUnderlyingAmount(_vaultToken: address, _vaultTokenAmount: uint256) -> uint256:
    if not self._isVaultToken(_vaultToken) or _vaultTokenAmount == 0:
        return 0 # invalid vault token or amount
    return self._getUnderlyingAmount(_vaultToken, _vaultTokenAmount)


@view
@internal
def _getUnderlyingAmount(_vaultToken: address, _vaultTokenAmount: uint256) -> uint256:
    return staticcall Erc4626Interface(_vaultToken).convertToAssets(_vaultTokenAmount)


# usd value


@view
@external
def getUsdValueOfVaultToken(_vaultToken: address, _vaultTokenAmount: uint256, _oracleRegistry: address = empty(address)) -> uint256:
    return self._getUsdValueOfVaultToken(_vaultToken, _vaultTokenAmount, _oracleRegistry)


@view
@internal
def _getUsdValueOfVaultToken(_vaultToken: address, _vaultTokenAmount: uint256, _oracleRegistry: address) -> uint256:
    asset: address = empty(address)
    underlyingAmount: uint256 = 0
    usdValue: uint256 = 0
    asset, underlyingAmount, usdValue = self._getUnderlyingData(_vaultToken, _vaultTokenAmount, _oracleRegistry)
    return usdValue


# all underlying data together


@view
@external
def getUnderlyingData(_vaultToken: address, _vaultTokenAmount: uint256, _oracleRegistry: address = empty(address)) -> (address, uint256, uint256):
    return self._getUnderlyingData(_vaultToken, _vaultTokenAmount, _oracleRegistry)


@view
@internal
def _getUnderlyingData(_vaultToken: address, _vaultTokenAmount: uint256, _oracleRegistry: address) -> (address, uint256, uint256):
    if _vaultTokenAmount == 0 or _vaultToken == empty(address):
        return empty(address), 0, 0 # bad inputs
    asset: address = self._getUnderlyingAsset(_vaultToken)
    if asset == empty(address):
        return empty(address), 0, 0 # invalid vault token
    underlyingAmount: uint256 = self._getUnderlyingAmount(_vaultToken, _vaultTokenAmount)
    usdValue: uint256 = self._getUsdValue(asset, underlyingAmount, _oracleRegistry)
    return asset, underlyingAmount, usdValue


@view
@internal
def _getUsdValue(_asset: address, _amount: uint256, _oracleRegistry: address) -> uint256:
    oracleRegistry: address = _oracleRegistry
    if _oracleRegistry == empty(address):
        oracleRegistry = staticcall AddyRegistry(ADDY_REGISTRY).getAddy(4)
    return staticcall OracleRegistry(oracleRegistry).getUsdValue(_asset, _amount)


# other


@view
@external
def totalAssets(_vaultToken: address) -> uint256:
    if not self._isVaultToken(_vaultToken):
        return 0 # invalid vault token
    return staticcall Erc4626Interface(_vaultToken).totalAssets()


@view
@external
def totalBorrows(_vaultToken: address) -> uint256:
    return 0 # TODO


###########
# Deposit #
###########


@external
def depositTokens(
    _asset: address,
    _amount: uint256,
    _vault: address,
    _recipient: address,
    _oracleRegistry: address = empty(address),
) -> (uint256, address, uint256, uint256, uint256):
    assert self.isActivated # dev: not activated
    assert self.indexOfAssetOpportunity[_asset][_vault] != 0 # dev: asset + vault not supported

    # pre balances
    preLegoBalance: uint256 = staticcall IERC20(_asset).balanceOf(self)

    # transfer deposit asset to this contract
    transferAmount: uint256 = min(_amount, staticcall IERC20(_asset).balanceOf(msg.sender))
    assert transferAmount != 0 # dev: nothing to transfer
    assert extcall IERC20(_asset).transferFrom(msg.sender, self, transferAmount, default_return_value=True) # dev: transfer failed

    # deposit assets into lego partner
    depositAmount: uint256 = min(transferAmount, staticcall IERC20(_asset).balanceOf(self))
    vaultTokenAmountReceived: uint256 = extcall Erc4626Interface(_vault).deposit(depositAmount, _recipient)
    assert vaultTokenAmountReceived != 0 # dev: no vault tokens received

    # refund if full deposit didn't get through
    currentLegoBalance: uint256 = staticcall IERC20(_asset).balanceOf(self)
    refundAssetAmount: uint256 = 0
    if currentLegoBalance > preLegoBalance:
        refundAssetAmount = currentLegoBalance - preLegoBalance
        assert extcall IERC20(_asset).transfer(msg.sender, refundAssetAmount, default_return_value=True) # dev: transfer failed
        depositAmount -= refundAssetAmount

    usdValue: uint256 = self._getUsdValue(_asset, depositAmount, _oracleRegistry)
    log FluidDeposit(msg.sender, _asset, _vault, depositAmount, usdValue, vaultTokenAmountReceived, _recipient)
    return depositAmount, _vault, vaultTokenAmountReceived, refundAssetAmount, usdValue


############
# Withdraw #
############


@external
def withdrawTokens(
    _asset: address,
    _amount: uint256,
    _vaultToken: address,
    _recipient: address,
    _oracleRegistry: address = empty(address),
) -> (uint256, uint256, uint256, uint256):
    assert self.isActivated # dev: not activated
    assert self.indexOfAssetOpportunity[_asset][_vaultToken] != 0 # dev: asset + vault not supported

    # pre balances
    preLegoVaultBalance: uint256 = staticcall IERC20(_vaultToken).balanceOf(self)

    # transfer vaults tokens to this contract
    transferVaultTokenAmount: uint256 = min(_amount, staticcall IERC20(_vaultToken).balanceOf(msg.sender))
    assert transferVaultTokenAmount != 0 # dev: nothing to transfer
    assert extcall IERC20(_vaultToken).transferFrom(msg.sender, self, transferVaultTokenAmount, default_return_value=True) # dev: transfer failed

    # withdraw assets from lego partner
    vaultTokenAmount: uint256 = min(transferVaultTokenAmount, staticcall IERC20(_vaultToken).balanceOf(self))
    assetAmountReceived: uint256 = extcall Erc4626Interface(_vaultToken).redeem(vaultTokenAmount, _recipient, self)
    assert assetAmountReceived != 0 # dev: no asset amount received

    # refund if full withdrawal didn't happen
    currentLegoVaultBalance: uint256 = staticcall IERC20(_vaultToken).balanceOf(self)
    refundVaultTokenAmount: uint256 = 0
    if currentLegoVaultBalance > preLegoVaultBalance:
        refundVaultTokenAmount = currentLegoVaultBalance - preLegoVaultBalance
        assert extcall IERC20(_vaultToken).transfer(msg.sender, refundVaultTokenAmount, default_return_value=True) # dev: transfer failed
        vaultTokenAmount -= refundVaultTokenAmount

    usdValue: uint256 = self._getUsdValue(_asset, assetAmountReceived, _oracleRegistry)
    log FluidWithdrawal(msg.sender, _asset, _vaultToken, assetAmountReceived, usdValue, vaultTokenAmount, _recipient)
    return assetAmountReceived, vaultTokenAmount, refundVaultTokenAmount, usdValue


##################
# Asset Registry #
##################


# settings


@external
def addAssetOpportunity(_asset: address, _vault: address) -> bool:
    assert msg.sender == staticcall AddyRegistry(ADDY_REGISTRY).governor() # dev: no perms

    # specific to lego
    assert self._getUnderlyingAsset(_vault) == _asset # dev: invalid asset or vault
    assert extcall IERC20(_asset).approve(_vault, max_value(uint256), default_return_value=True) # dev: max approval failed

    self._addAssetOpportunity(_asset, _vault)
    return True


@external
def removeAssetOpportunity(_asset: address, _vault: address) -> bool:
    assert msg.sender == staticcall AddyRegistry(ADDY_REGISTRY).governor() # dev: no perms

    self._removeAssetOpportunity(_asset, _vault)
    assert extcall IERC20(_asset).approve(_vault, 0, default_return_value=True) # dev: approval failed
    return True


# internal / utils


@internal
def _addAssetOpportunity(_asset: address, _vault: address):
    assert self.indexOfAssetOpportunity[_asset][_vault] == 0 # dev: asset + vault token already added
    assert empty(address) not in [_asset, _vault] # dev: invalid addresses

    aid: uint256 = self.numAssetOpportunities[_asset]
    if aid == 0:
        aid = 1 # not using 0 index
    self.assetOpportunities[_asset][aid] = _vault
    self.indexOfAssetOpportunity[_asset][_vault] = aid
    self.numAssetOpportunities[_asset] = aid + 1
    self.vaultToAsset[_vault] = _asset

    # add asset
    self._addAsset(_asset)

    log AssetOpportunityAdded(_asset, _vault)


@internal
def _addAsset(_asset: address):
    if self.indexOfAsset[_asset] != 0:
        return
    aid: uint256 = self.numAssets
    if aid == 0:
        aid = 1 # not using 0 index
    self.assets[aid] = _asset
    self.indexOfAsset[_asset] = aid
    self.numAssets = aid + 1


@internal
def _removeAssetOpportunity(_asset: address, _vault: address):
    targetIndex: uint256 = self.indexOfAssetOpportunity[_asset][_vault]
    assert targetIndex != 0 # dev: asset + vault token not found

    numOpportunities: uint256 = self.numAssetOpportunities[_asset]
    assert numOpportunities > 1 # dev: no opportunities to remove

    # update data
    lastIndex: uint256 = numOpportunities - 1
    self.numAssetOpportunities[_asset] = lastIndex
    self.indexOfAssetOpportunity[_asset][_vault] = 0
    self.vaultToAsset[_vault] = empty(address)

    # shift to replace the removed one
    if targetIndex != lastIndex:
        lastVaultToken: address = self.assetOpportunities[_asset][lastIndex]
        self.assetOpportunities[_asset][targetIndex] = lastVaultToken
        self.indexOfAssetOpportunity[_asset][lastVaultToken] = targetIndex

    # remove asset
    if lastIndex <= 1:
        self._removeAsset(_asset)

    log AssetOpportunityRemoved(_asset, _vault)


@internal
def _removeAsset(_asset: address):
    numAssets: uint256 = self.numAssets
    if numAssets <= 1:
        return

    targetIndex: uint256 = self.indexOfAsset[_asset]
    if targetIndex == 0:
        return

    # update data
    lastIndex: uint256 = numAssets - 1
    self.numAssets = lastIndex
    self.indexOfAsset[_asset] = 0

    # shift to replace the removed one
    if targetIndex != lastIndex:
        lastAsset: address = self.assets[lastIndex]
        self.assets[targetIndex] = lastAsset
        self.indexOfAsset[lastAsset] = targetIndex


#################
# Recover Funds #
#################


@external
def recoverFunds(_asset: address, _recipient: address) -> bool:
    assert msg.sender == staticcall AddyRegistry(ADDY_REGISTRY).governor() # dev: no perms

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
    log FluidLegoIdSet(_legoId)
    return True