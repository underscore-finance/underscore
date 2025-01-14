# @version 0.4.0

from ethereum.ercs import IERC20
import interfaces.LegoInterface as LegoPartner

interface LegoRegistry:
    def getLegoAddr(_legoId: uint256) -> address: view

event AgenticLegoDeposit:
    user: indexed(address)
    asset: indexed(address)
    vault: indexed(address)
    assetAmountDeposited: uint256
    vaultToken: address
    vaultTokenAmountReceived: uint256
    legoId: uint256
    legoAddr: address

# admin
owner: public(address)
agent: public(address)

# config
legoRegistry: public(address)
initialized: public(bool)

API_VERSION: constant(String[28]) = "0.0.1"


@deploy
def __init__():
    # make sure original reference contract can't be initialized
    self.initialized = True


@external
def initialize(_legoRegistry: address, _owner: address, _agent: address) -> bool:
    assert not self.initialized # dev: can only initialize once
    self.initialized = True

    assert empty(address) not in [_legoRegistry, _owner, _agent] # dev: invalid addrs
    self.legoRegistry = _legoRegistry
    self.owner = _owner
    self.agent = _agent

    return True


@pure
@external
def apiVersion() -> String[28]:
    return API_VERSION


###########
# Deposit #
###########


@external
def depositTokens(
    _legoId: uint256,
    _asset: address,
    _vault: address = empty(address),
    _amount: uint256 = max_value(uint256),
) -> (uint256, address, uint256):
    assert msg.sender in [self.owner, self.agent] # dev: no perms
    return self._depositTokens(_legoId, _asset, _vault, _amount)


@external
def depositTokensWithTransfer(
    _legoId: uint256,
    _asset: address,
    _vault: address = empty(address),
    _amount: uint256 = max_value(uint256),
    _shouldSweep: bool = True,
) -> (uint256, address, uint256):
    assert msg.sender in [self.owner, self.agent] # dev: no perms
    transferAmount: uint256 = min(_amount, staticcall IERC20(_asset).balanceOf(msg.sender))
    assert extcall IERC20(_asset).transferFrom(msg.sender, self, transferAmount, default_return_value=True) # dev: transfer failed
    if _shouldSweep:
        transferAmount = max_value(uint256)
    return self._depositTokens(_legoId, _asset, _vault, transferAmount)


@internal
def _depositTokens(
    _legoId: uint256,
    _asset: address,
    _vault: address,
    _amount: uint256,
) -> (uint256, address, uint256):
    legoAddr: address = staticcall LegoRegistry(self.legoRegistry).getLegoAddr(_legoId)
    assert legoAddr != empty(address) # dev: invalid lego

    # finalize amount
    intendedDepositAmount: uint256 = min(_amount, staticcall IERC20(_asset).balanceOf(self))
    assert intendedDepositAmount != 0 # dev: nothing to transfer
    assert extcall IERC20(_asset).approve(legoAddr, intendedDepositAmount, default_return_value=True) # dev: approval failed

    # deposit into lego partner
    assetAmountDeposited: uint256 = 0
    vaultToken: address = empty(address)
    vaultTokenAmountReceived: uint256 = 0
    assetAmountDeposited, vaultToken, vaultTokenAmountReceived = extcall LegoPartner(legoAddr).depositTokens(_asset, _vault, intendedDepositAmount)
    assert extcall IERC20(_asset).approve(legoAddr, 0, default_return_value=True) # dev: approval failed

    log AgenticLegoDeposit(msg.sender, _asset, _vault, assetAmountDeposited, vaultToken, vaultTokenAmountReceived, _legoId, legoAddr)
    return assetAmountDeposited, vaultToken, vaultTokenAmountReceived