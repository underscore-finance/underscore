# @version 0.4.0

implements: LegoPartner

from ethereum.ercs import IERC20
import interfaces.LegoInterface as LegoPartner

interface Erc4626Interface:
    def redeem(_vaultTokenAmount: uint256, _recipient: address, _owner: address) -> uint256: nonpayable
    def deposit(_assetAmount: uint256, _recipient: address) -> uint256: nonpayable
    def asset() -> address: view

interface AgentFactory:
    def isAgenticWallet(_wallet: address) -> bool: view

interface LegoRegistry:
    def governor() -> address: view

event MockLegoDeposit:
    user: indexed(address)
    asset: indexed(address)
    vaultToken: indexed(address)
    assetAmountDeposited: uint256
    vaultTokenAmountReceived: uint256

event MockLegoWithdrawal:
    user: indexed(address)
    asset: indexed(address)
    vaultToken: indexed(address)
    assetAmountReceived: uint256
    vaultTokenAmountBurned: uint256

event FundsRecovered:
    asset: indexed(address)
    recipient: indexed(address)
    balance: uint256

event MockLegoIdSet:
    legoId: uint256

event MockLegoActivated:
    isActivated: bool

# mock data
mockAsset: public(address)
mockVault: public(address)

# config
legoId: public(uint256)
isActivated: public(bool)

LEGO_REGISTRY: immutable(address)
AGENT_FACTORY: immutable(address)


@deploy
def __init__(_mockAsset: address, _mockVault: address, _legoRegistry: address, _agentFactory: address):
    assert empty(address) not in [_mockAsset, _mockVault, _legoRegistry, _agentFactory] # dev: invalid addrs
    LEGO_REGISTRY = _legoRegistry
    AGENT_FACTORY = _agentFactory
    self.isActivated = True

    # approved asset + vault
    self.mockAsset = _mockAsset
    self.mockVault = _mockVault


@view
@internal
def _validateAssetAndVault(_asset: address, _vault: address):
    assert self.isActivated # dev: not activated
    assert staticcall AgentFactory(AGENT_FACTORY).isAgenticWallet(msg.sender) # dev: no perms

    assert _asset == self.mockAsset # dev: invalid asset
    assert _vault == self.mockVault # dev: invalid vault


###########
# Deposit #
###########


@external
def depositTokens(_asset: address, _amount: uint256, _vault: address) -> (uint256, address, uint256):
    self._validateAssetAndVault(_asset, _vault)

    # pre balances
    preLegoBalance: uint256 = staticcall IERC20(_asset).balanceOf(self)

    # transfer deposit asset to this contract
    transferAmount: uint256 = min(_amount, staticcall IERC20(_asset).balanceOf(msg.sender))
    assert transferAmount != 0 # dev: nothing to transfer
    assert extcall IERC20(_asset).transferFrom(msg.sender, self, transferAmount, default_return_value=True) # dev: transfer failed

    # deposit assets into lego partner
    depositAmount: uint256 = min(transferAmount, staticcall IERC20(_asset).balanceOf(self))
    assert extcall IERC20(_asset).approve(_vault, depositAmount, default_return_value=True) # dev: approval failed
    vaultTokenAmountReceived: uint256 = extcall Erc4626Interface(_vault).deposit(depositAmount, msg.sender)
    assert vaultTokenAmountReceived != 0 # dev: no vault tokens received
    assert extcall IERC20(_asset).approve(_vault, 0, default_return_value=True) # dev: approval failed

    # refund if full deposit didn't get through
    currentLegoBalance: uint256 = staticcall IERC20(_asset).balanceOf(self)
    refundAmount: uint256 = 0
    if currentLegoBalance > preLegoBalance:
        refundAmount = currentLegoBalance - preLegoBalance
        assert extcall IERC20(_asset).transfer(msg.sender, refundAmount, default_return_value=True) # dev: transfer failed

    actualDepositAmount: uint256 = depositAmount - refundAmount
    log MockLegoDeposit(msg.sender, _asset, _vault, actualDepositAmount, vaultTokenAmountReceived)
    return actualDepositAmount, _vault, vaultTokenAmountReceived


############
# Withdraw #
############


@external
def withdrawTokens(_asset: address, _amount: uint256, _vaultToken: address) -> (uint256, uint256):
    self._validateAssetAndVault(_asset, _vaultToken)

    # pre balances
    preLegoVaultBalance: uint256 = staticcall IERC20(_vaultToken).balanceOf(self)

    # transfer vaults tokens to this contract
    transferVaultTokenAmount: uint256 = min(_amount, staticcall IERC20(_vaultToken).balanceOf(msg.sender))
    assert transferVaultTokenAmount != 0 # dev: nothing to transfer
    assert extcall IERC20(_vaultToken).transferFrom(msg.sender, self, transferVaultTokenAmount, default_return_value=True) # dev: transfer failed

    # withdraw assets from lego partner
    withdrawVaultTokenAmount: uint256 = min(transferVaultTokenAmount, staticcall IERC20(_vaultToken).balanceOf(self))
    assetAmountReceived: uint256 = extcall Erc4626Interface(_vaultToken).redeem(withdrawVaultTokenAmount, msg.sender, self)
    assert assetAmountReceived != 0 # dev: no asset amount received

    # refund if full withdrawal didn't happen
    currentLegoVaultBalance: uint256 = staticcall IERC20(_vaultToken).balanceOf(self)
    refundVaultTokenAmount: uint256 = 0
    if currentLegoVaultBalance > preLegoVaultBalance:
        refundVaultTokenAmount = currentLegoVaultBalance - preLegoVaultBalance
        assert extcall IERC20(_vaultToken).transfer(msg.sender, refundVaultTokenAmount, default_return_value=True) # dev: transfer failed

    vaultTokenAmountBurned: uint256 = withdrawVaultTokenAmount - refundVaultTokenAmount
    log MockLegoWithdrawal(msg.sender, _asset, _vaultToken, assetAmountReceived, vaultTokenAmountBurned)
    return assetAmountReceived, vaultTokenAmountBurned


#################
# Recover Funds #
#################


@external
def recoverFunds(_asset: address, _recipient: address) -> bool:
    assert msg.sender == staticcall LegoRegistry(LEGO_REGISTRY).governor() # dev: no perms

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
    assert msg.sender == LEGO_REGISTRY # dev: no perms
    assert self.legoId == 0 # dev: already set
    self.legoId = _legoId
    log MockLegoIdSet(_legoId)
    return True


############
# Activate #
############


@external
def activate(_shouldActivate: bool):
    assert msg.sender == staticcall LegoRegistry(LEGO_REGISTRY).governor() # dev: no perms
    self.isActivated = _shouldActivate
    log MockLegoActivated(_shouldActivate)