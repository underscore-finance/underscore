# @version 0.4.0
# pragma optimize codesize

from ethereum.ercs import IERC20
from interfaces import LegoDex
from interfaces import LegoYield

interface PriceSheets:
    def getCombinedSubData(_agent: address, _agentPaidThru: uint256, _protocolPaidThru: uint256, _oracleRegistry: address) -> (SubPaymentInfo, SubPaymentInfo): view
    def getCombinedTxCostData(_agent: address, _action: ActionType, _usdValue: uint256, _oracleRegistry: address) -> (TxCostInfo, TxCostInfo): view
    def getAgentSubPriceData(_agent: address) -> SubscriptionInfo: view
    def protocolSubPriceData() -> SubscriptionInfo: view
    def protocolRecipient() -> address: view

interface OracleRegistry:
    def getAssetAmount(_asset: address, _usdValue: uint256, _shouldRaise: bool = False) -> uint256: view
    def getUsdValue(_asset: address, _amount: uint256, _shouldRaise: bool = False) -> uint256: view
    def getEthUsdValue(_amount: uint256, _shouldRaise: bool = False) -> uint256: view

interface LegoRegistry:
    def getUnderlyingForUser(_user: address, _asset: address) -> uint256: view
    def getLegoAddr(_legoId: uint256) -> address: view
    def isValidLegoId(_legoId: uint256) -> bool: view
    def legoHelper() -> address: view

interface WethContract:
    def withdraw(_amount: uint256): nonpayable
    def deposit(): payable

interface LegoHelper:
    def getTotalUnderlyingForUser(_user: address, _underlyingAsset: address) -> uint256: view

interface AddyRegistry:
    def getAddy(_addyId: uint256) -> address: view

flag ActionType:
    DEPOSIT
    WITHDRAWAL
    REBALANCE
    TRANSFER
    SWAP
    CONVERSION

struct TrialFundsClawback:
    legoId: uint256
    vaultToken: address

struct AgentInfo:
    isActive: bool
    installBlock: uint256
    paidThroughBlock: uint256
    allowedAssets: DynArray[address, MAX_ASSETS]
    allowedLegoIds: DynArray[uint256, MAX_LEGOS]
    allowedActions: AllowedActions

struct CoreData:
    owner: address
    wallet: address,
    walletConfig: address
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

struct ProtocolSub:
    installBlock: uint256
    paidThroughBlock: uint256

struct AllowedActions:
    isSet: bool
    canDeposit: bool
    canWithdraw: bool
    canRebalance: bool
    canTransfer: bool
    canSwap: bool
    canConvert: bool

struct Signature:
    signature: Bytes[65]
    signer: address
    expiration: uint256

struct ReserveAsset:
    asset: address
    amount: uint256

struct ActionInstruction:
    action: ActionType
    legoId: uint256
    asset: address
    vault: address
    amount: uint256
    recipient: address
    altLegoId: uint256
    altVault: address
    altAsset: address
    altAmount: uint256

struct SubscriptionInfo:
    asset: address
    usdValue: uint256
    trialPeriod: uint256
    payPeriod: uint256

event TransactionFeePaid:
    agent: indexed(address)
    action: ActionType
    transactionUsdValue: uint256
    agentAsset: indexed(address)
    agentAssetAmount: uint256
    agentUsdValue: uint256
    protocolRecipient: address
    protocolAsset: indexed(address)
    protocolAssetAmount: uint256
    protocolUsdValue: uint256

event BatchTransactionFeesPaid:
    agent: indexed(address)
    agentAsset: indexed(address)
    agentAssetAmount: uint256
    agentUsdValue: uint256
    protocolRecipient: address
    protocolAsset: indexed(address)
    protocolAssetAmount: uint256
    protocolUsdValue: uint256

event AgentSubscriptionPaid:
    agent: indexed(address)
    asset: indexed(address)
    amount: uint256
    usdValue: uint256
    paidThroughBlock: uint256

event ProtocolSubscriptionPaid:
    recipient: indexed(address)
    asset: indexed(address)
    amount: uint256
    usdValue: uint256
    paidThroughBlock: uint256

event WhitelistAddrSet:
    addr: indexed(address)
    isAllowed: bool

event AgentAdded:
    agent: indexed(address)
    allowedAssets: uint256
    allowedLegoIds: uint256

event AgentModified:
    agent: indexed(address)
    allowedAssets: uint256
    allowedLegoIds: uint256

event AgentDisabled:
    agent: indexed(address)
    prevAllowedAssets: uint256
    prevAllowedLegoIds: uint256

event LegoIdAddedToAgent:
    agent: indexed(address)
    legoId: indexed(uint256)

event AssetAddedToAgent:
    agent: indexed(address)
    asset: indexed(address)

event AllowedActionsModified:
    agent: indexed(address)
    canDeposit: bool
    canWithdraw: bool
    canRebalance: bool
    canTransfer: bool
    canSwap: bool
    canConvert: bool

event ReserveAssetSet:
    asset: indexed(address)
    amount: uint256

event TrialFundsClawedBack:
    clawedBackAmount: uint256
    remainingAmount: uint256

wallet: public(address)

# settings
owner: public(address) # owner of the wallet
protocolSub: public(ProtocolSub) # subscription info
reserveAssets: public(HashMap[address, uint256]) # asset -> reserve amount
agentSettings: public(HashMap[address, AgentInfo]) # agent -> agent info
isRecipientAllowed: public(HashMap[address, bool]) # recipient -> is allowed

# config
addyRegistry: public(address)
wethAddr: public(address)
initialized: public(bool)

API_VERSION: constant(String[28]) = "0.0.1"

MAX_ASSETS: constant(uint256) = 25
MAX_LEGOS: constant(uint256) = 10
MAX_INSTRUCTIONS: constant(uint256) = 20

# registry ids
AGENT_FACTORY_ID: constant(uint256) = 1
LEGO_REGISTRY_ID: constant(uint256) = 2
PRICE_SHEETS_ID: constant(uint256) = 3
ORACLE_REGISTRY_ID: constant(uint256) = 4


@deploy
def __init__():
    # make sure original reference contract can't be initialized
    self.initialized = True


@external
def initialize(
    _wallet: address,
    _addyRegistry: address,
    _wethAddr: address,
    _trialFundsAsset: address,
    _trialFundsAmount: uint256,
    _owner: address,
    _initialAgent: address,
) -> bool:
    """
    @notice Sets up the initial state of the wallet template
    @dev Can only be called once and sets core contract parameters
    @param _wallet The address of the wallet contract
    @param _addyRegistry The address of the core registry contract
    @param _wethAddr The address of the WETH contract
    @param _trialFundsAsset The address of the gift asset
    @param _trialFundsAmount The amount of the gift asset
    @param _owner The address that will own this wallet
    @param _initialAgent The address of the initial AI agent (if any)
    @return bool True if initialization was successful
    """
    assert not self.initialized # dev: can only initialize once
    self.initialized = True

    assert empty(address) not in [_wallet, _addyRegistry, _wethAddr, _owner] # dev: invalid addrs
    assert _initialAgent != _owner # dev: agent cannot be owner
    self.wallet = _wallet
    self.addyRegistry = _addyRegistry
    self.wethAddr = _wethAddr
    self.owner = _owner

    priceSheets: address = staticcall AddyRegistry(_addyRegistry).getAddy(PRICE_SHEETS_ID)

    # initial agent setup
    if _initialAgent != empty(address):
        subInfo: SubscriptionInfo = staticcall PriceSheets(priceSheets).getAgentSubPriceData(_initialAgent)
        paidThroughBlock: uint256 = 0
        if subInfo.usdValue != 0:
            paidThroughBlock = block.number + subInfo.trialPeriod
        self.agentSettings[_initialAgent] = AgentInfo(
            isActive=True,
            installBlock=block.number,
            paidThroughBlock=paidThroughBlock,
            allowedAssets=[],
            allowedLegoIds=[],
            allowedActions=empty(AllowedActions),
        )
        log AgentAdded(_initialAgent, 0, 0)

    # protocol subscription
    protocolSub: ProtocolSub = empty(ProtocolSub)
    protocolSub.installBlock = block.number
    subInfo: SubscriptionInfo = staticcall PriceSheets(priceSheets).protocolSubPriceData()
    if subInfo.usdValue != 0:
        protocolSub.paidThroughBlock = block.number + subInfo.trialPeriod
    self.protocolSub = protocolSub

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


#############
# Utilities #
#############


@view
@internal
def _getCoreData() -> CoreData:
    addyRegistry: address = self.addyRegistry
    wallet: address = self.wallet
    return CoreData(
        wallet=wallet,
        walletConfig=self,
        legoRegistry=staticcall AddyRegistry(addyRegistry).getAddy(LEGO_REGISTRY_ID),
        priceSheets=staticcall AddyRegistry(addyRegistry).getAddy(PRICE_SHEETS_ID),
        oracleRegistry=staticcall AddyRegistry(addyRegistry).getAddy(ORACLE_REGISTRY_ID),
        trialFundsAsset=WalletFunds(wallet).trialFundsAsset(),
        trialFundsInitialAmount=WalletFunds(wallet).trialFundsInitialAmount(),
    )


@view
@external
def getAvailableTxAmount(
    _asset: address,
    _wantedAmount: uint256,
    _shouldCheckTrialFunds: bool,
    _cd: CoreData,
) -> uint256:
    tokenBalance: uint256 = self._getAvailBalAfterTrialFunds(_asset, _shouldCheckTrialFunds, _cd.trialFundsAsset, _cd.trialFundsAmount, _cd.wallet, _cd.legoRegistry)
    reservedAmount: uint256 = self.reserveAssets[_asset]
    
    assert tokenBalance > reservedAmount # dev: insufficient balance after reserve
    availableAmount: uint256 = tokenBalance - reservedAmount
    
    amount: uint256 = min(_wantedAmount, availableAmount)
    assert amount != 0 # dev: no funds available

    return amount


@view
@internal
def _getAvailBalAfterTrialFunds(
    _asset: address,
    _shouldCheckTrialFunds: bool,
    _trialFundsAsset: address,
    _trialFundsAmount: uint256,
    _wallet: address,
    _legoHelper: address,
) -> uint256:
    userBalance: uint256 = staticcall IERC20(_asset).balanceOf(_wallet)
    if _asset != _trialFundsAsset or not _shouldCheckTrialFunds:
        return userBalance

    # sufficient trial funds already deployed
    totalUnderlying: uint256 = staticcall LegoHelper(_legoHelper).getTotalUnderlyingForUser(_wallet, _asset)
    if totalUnderlying >= _trialFundsAmount:
        return userBalance

    lockedAmount: uint256 = _trialFundsAmount - totalUnderlying
    availAmount: uint256 = 0
    if lockedAmount < userBalance:
        availAmount = userBalance - lockedAmount

    return availAmount


################
# Agent Access #
################


@view
@external
def canAgentAccess(
    _agent: address,
    _action: ActionType,
    _assets: DynArray[address, MAX_ASSETS],
    _legoIds: DynArray[uint256, MAX_LEGOS],
) -> bool:
    return self._canAgentAccess(self.agentSettings[_agent], _action, _assets, _legoIds)


@view
@internal
def _canAgentAccess(
    _agent: AgentInfo,
    _action: ActionType,
    _assets: DynArray[address, MAX_ASSETS],
    _legoIds: DynArray[uint256, MAX_LEGOS],
) -> bool:
    if not _agent.isActive:
        return False

    # check allowed actions
    if not self._canAgentPerformAction(_action, _agent.allowedActions):
        return False

    # check allowed assets
    if len(_agent.allowedAssets) != 0:
        for i: uint256 in range(len(_assets), bound=MAX_ASSETS):
            asset: address = _assets[i]
            if asset != empty(address) and asset not in _agent.allowedAssets:
                return False

    # check allowed lego ids
    if len(_agent.allowedLegoIds) != 0:
        for i: uint256 in range(len(_legoIds), bound=MAX_LEGOS):
            legoId: uint256 = _legoIds[i]
            if legoId != 0 and legoId not in _agent.allowedLegoIds:
                return False

    return True


@view
@internal
def _canAgentPerformAction(_action: ActionType, _allowedActions: AllowedActions) -> bool:
    if not _allowedActions.isSet:
        return True
    if _action == ActionType.DEPOSIT:
        return _allowedActions.canDeposit
    elif _action == ActionType.WITHDRAWAL:
        return _allowedActions.canWithdraw
    elif _action == ActionType.REBALANCE:
        return _allowedActions.canRebalance
    elif _action == ActionType.TRANSFER:
        return _allowedActions.canTransfer
    elif _action == ActionType.SWAP:
        return _allowedActions.canSwap
    elif _action == ActionType.CONVERSION:
        return _allowedActions.canConvert
    else:
        return False


#####################
# Transaction Costs #
#####################


@view
@internal
def _aggregateBatchTxCostData(
    _aggCostData: TransactionCost,
    _agent: address,
    _isSignerAgent: bool,
    _action: ActionType,
    _usdValue: uint256,
    _priceSheets: address,
) -> TransactionCost:
    if not _isSignerAgent or _usdValue == 0:
        return _aggCostData

    aggCostData: TransactionCost = _aggCostData
    txCost: TransactionCost = staticcall PriceSheets(_priceSheets).getTransactionCost(_agent, _action, _usdValue)

    # agent asset
    if aggCostData.agentAsset == empty(address) and txCost.agentAsset != empty(address):
        aggCostData.agentAsset = txCost.agentAsset

    # protocol asset
    if aggCostData.protocolAsset == empty(address) and txCost.protocolAsset != empty(address):
        aggCostData.protocolAsset = txCost.protocolAsset

    # protocol recipient
    if aggCostData.protocolRecipient == empty(address) and txCost.protocolRecipient != empty(address):
        aggCostData.protocolRecipient = txCost.protocolRecipient

    # aggregate amounts / usd values
    aggCostData.agentAssetAmount += txCost.agentAssetAmount
    aggCostData.protocolAssetAmount += txCost.protocolAssetAmount
    aggCostData.agentUsdValue += txCost.agentUsdValue
    aggCostData.protocolUsdValue += txCost.protocolUsdValue

    return aggCostData


##########################
# Subscription + Tx Fees #
##########################


@external
def handleSubscriptionsAndPermissions(
    _agent: address,
    _action: ActionType,
    _assets: DynArray[address, MAX_ASSETS],
    _legoIds: DynArray[uint256, MAX_LEGOS],
    _cd: CoreData,
) -> (SubPaymentInfo, SubPaymentInfo):
    assert msg.sender == self.wallet # dev: no perms

    # check if agent can perform action with assets and legos
    userAgentData: AgentInfo = empty(AgentInfo)
    if _agent != empty(address):
        userAgentData = self.agentSettings[_agent]
        assert self._canAgentAccess(userAgentData, _action, _assets, _legoIds) # dev: agent not allowed

    userProtocolData: ProtocolSub = self.protocolSub

    # get latest sub data for agent and protocol
    protocolSub: SubPaymentInfo = empty(SubPaymentInfo)
    agentSub: SubPaymentInfo = empty(SubPaymentInfo)
    protocolSub, agentSub = staticcall PriceSheets(_cd.priceSheets).getCombinedSubData(_agent, userAgentData.paidThroughBlock, userProtocolData.paidThroughBlock, _cd.oracleRegistry)

    # check if sufficient funds
    self._checkIfSufficientFunds(protocolSub.asset, protocolSub.amount, agentSub.asset, agentSub.amount, _cd)

    # update and save new data
    if protocolSub.didChange:
        userProtocolData.paidThroughBlock = protocolSub.paidThroughBlock
        self.protocolSub = userProtocolData
    if agentSub.didChange:
        userAgentData.paidThroughBlock = agentSub.paidThroughBlock
        self.agentSettings[_agent] = userAgentData

    # actual payments will happen from wallet
    return protocolSub, agentSub


@view
@external
def getTransactionCosts(_agent: address, _action: ActionType, _usdValue: uint256, _cd: CoreData) -> (TxCostInfo, TxCostInfo):
    protocolCost: TxCostInfo = empty(TxCostInfo)
    agentCost: TxCostInfo = empty(TxCostInfo)
    protocolCost, agentCost = staticcall PriceSheets(_cd.priceSheets).getCombinedTxCostData(_agent, _action, _usdValue, _cd.oracleRegistry)

    # check if sufficient funds
    self._checkIfSufficientFunds(protocolCost.asset, protocolCost.amount, agentCost.asset, agentCost.amount, _cd)

    # actual payments will happen from wallet
    return protocolCost, agentCost


@view
@internal
def _checkIfSufficientFunds(_protocolAsset: address, _protocolAmount: uint256, _agentAsset: address, _agentAmount: uint256, _cd: CoreData):

    # check if any of these assets are also trial funds asset
    trialFundsCurrentBal: uint256 = 0
    trialFundsDeployed: uint256 = 0
    if _protocolAsset == _cd.trialFundsAsset or _agentAsset == _cd.trialFundsAsset:
        trialFundsCurrentBal = staticcall IERC20(_cd.trialFundsAsset).balanceOf(_cd.wallet)
        trialFundsDeployed = staticcall LegoRegistry(_cd.legoRegistry).getUnderlyingForUser(_cd.wallet, _cd.trialFundsAsset)

    # check if can make protocol payment
    if _protocolAmount != 0:
        availBalForProtocol: uint256 = self._getAvailBalAfterTrialFunds(_protocolAsset, _cd.wallet, _cd.trialFundsAsset, _cd.trialFundsInitialAmount, trialFundsCurrentBal, trialFundsDeployed)
        assert availBalForProtocol >= _protocolAmount # dev: insufficient balance for protocol subscription payment

        # update trial funds balance
        if _protocolAsset == _cd.trialFundsAsset:
            trialFundsCurrentBal -= _protocolAmount

    # check if can make agent payment
    if _agentAmount != 0:
        availBalForAgent: uint256 = self._getAvailBalAfterTrialFunds(_agentAsset, _cd.wallet, _cd.trialFundsAsset, _cd.trialFundsInitialAmount, trialFundsCurrentBal, trialFundsDeployed)
        assert availBalForAgent >= _agentAmount # dev: insufficient balance for agent subscription payment


@view
@internal
def _getAvailBalAfterTrialFunds(
    _asset: address,
    _wallet: address,
    _trialFundsAsset: address,
    _trialFundsInitialAmount: uint256,
    _trialFundsCurrentBal: uint256,
    _trialFundsDeployed: uint256,
) -> uint256:
    if _asset != _trialFundsAsset:
        return staticcall IERC20(_asset).balanceOf(_wallet)

    # sufficient trial funds already deployed
    if _trialFundsDeployed >= _trialFundsInitialAmount:
        return _trialFundsCurrentBal

    lockedAmount: uint256 = _trialFundsInitialAmount - _trialFundsDeployed
    availAmount: uint256 = 0
    if lockedAmount < _trialFundsCurrentBal:
        availAmount = _trialFundsCurrentBal - lockedAmount

    return availAmount


##################
# Agent Settings #
##################


# add or modify agent settings


@nonreentrant
@external
def addOrModifyAgent(
    _agent: address,
    _allowedAssets: DynArray[address, MAX_ASSETS] = [],
    _allowedLegoIds: DynArray[uint256, MAX_LEGOS] = [],
    _allowedActions: AllowedActions = empty(AllowedActions),
) -> bool:
    """
    @notice Adds a new agent or modifies an existing agent's permissions
        If empty arrays are provided, the agent has access to all assets and lego ids
    @dev Can only be called by the owner
    @param _agent The address of the agent to add or modify
    @param _allowedAssets List of assets the agent can interact with
    @param _allowedLegoIds List of lego IDs the agent can use
    @param _allowedActions The actions the agent can perform
    @return bool True if the agent was successfully added or modified
    """
    owner: address = self.owner
    assert msg.sender == owner # dev: no perms
    assert _agent != owner # dev: agent cannot be owner
    assert _agent != empty(address) # dev: invalid agent

    agentInfo: AgentInfo = self.agentSettings[_agent]
    agentInfo.isActive = True

    # allowed actions
    agentInfo.allowedActions = _allowedActions
    agentInfo.allowedActions.isSet = self._hasAllowedActionsSet(_allowedActions)

    # sanitize other input data
    agentInfo.allowedAssets, agentInfo.allowedLegoIds = self._sanitizeAgentInputData(_allowedAssets, _allowedLegoIds)

    # get subscription info
    priceSheets: address = staticcall AddyRegistry(self.addyRegistry).getAddy(PRICE_SHEETS_ID)
    subInfo: SubscriptionInfo = staticcall PriceSheets(priceSheets).getAgentSubPriceData(_agent)
    
    isNewAgent: bool = (agentInfo.installBlock == 0)
    if isNewAgent:
        agentInfo.installBlock = block.number
        if subInfo.usdValue != 0:
            agentInfo.paidThroughBlock = block.number + subInfo.trialPeriod

    # may not have had sub setup before
    elif subInfo.usdValue != 0:
        agentInfo.paidThroughBlock = max(agentInfo.paidThroughBlock, agentInfo.installBlock + subInfo.trialPeriod)

    self.agentSettings[_agent] = agentInfo

    # log event
    if isNewAgent:
        log AgentAdded(_agent, len(agentInfo.allowedAssets), len(agentInfo.allowedLegoIds))
    else:
        log AgentModified(_agent, len(agentInfo.allowedAssets), len(agentInfo.allowedLegoIds))
    return True


@view
@internal
def _sanitizeAgentInputData(
    _allowedAssets: DynArray[address, MAX_ASSETS],
    _allowedLegoIds: DynArray[uint256, MAX_LEGOS],
) -> (DynArray[address, MAX_ASSETS], DynArray[uint256, MAX_LEGOS]):

    # nothing to do here
    if len(_allowedAssets) == 0 and len(_allowedLegoIds) == 0:
        return _allowedAssets, _allowedLegoIds

    # sanitize and dedupe assets
    cleanAssets: DynArray[address, MAX_ASSETS] = []
    for i: uint256 in range(len(_allowedAssets), bound=MAX_ASSETS):
        asset: address = _allowedAssets[i]
        if asset == empty(address):
            continue
        if asset not in cleanAssets:
            cleanAssets.append(asset)

    # validate and dedupe lego ids
    cleanLegoIds: DynArray[uint256, MAX_LEGOS] = []
    if len(_allowedLegoIds) != 0:
        legoRegistry: address = staticcall AddyRegistry(self.addyRegistry).getAddy(LEGO_REGISTRY_ID)
        for i: uint256 in range(len(_allowedLegoIds), bound=MAX_LEGOS):
            legoId: uint256 = _allowedLegoIds[i]
            if not staticcall LegoRegistry(legoRegistry).isValidLegoId(legoId):
                continue
            if legoId not in cleanLegoIds:
                cleanLegoIds.append(legoId)

    return cleanAssets, cleanLegoIds


# disable agent


@nonreentrant
@external
def disableAgent(_agent: address) -> bool:
    """
    @notice Disables an existing agent
    @dev Can only be called by the owner
    @param _agent The address of the agent to disable
    @return bool True if the agent was successfully disabled
    """
    assert msg.sender == self.owner # dev: no perms

    agentInfo: AgentInfo = self.agentSettings[_agent]
    assert agentInfo.isActive # dev: agent not active
    agentInfo.isActive = False
    self.agentSettings[_agent] = agentInfo

    log AgentDisabled(_agent, len(agentInfo.allowedAssets), len(agentInfo.allowedLegoIds))
    return True


# add lego id for agent


@nonreentrant
@external
def addLegoIdForAgent(_agent: address, _legoId: uint256) -> bool:
    """
    @notice Adds a lego ID to an agent's allowed legos
    @dev Can only be called by the owner
    @param _agent The address of the agent
    @param _legoId The lego ID to add
    @return bool True if the lego ID was successfully added
    """
    assert msg.sender == self.owner # dev: no perms

    agentInfo: AgentInfo = self.agentSettings[_agent]
    assert agentInfo.isActive # dev: agent not active

    legoRegistry: address = staticcall AddyRegistry(self.addyRegistry).getAddy(LEGO_REGISTRY_ID)
    assert staticcall LegoRegistry(legoRegistry).isValidLegoId(_legoId)
    assert _legoId not in agentInfo.allowedLegoIds # dev: lego id already saved

    # save data
    agentInfo.allowedLegoIds.append(_legoId)
    self.agentSettings[_agent] = agentInfo

    # log event
    log LegoIdAddedToAgent(_agent, _legoId)
    return True


# add asset for agent


@nonreentrant
@external
def addAssetForAgent(_agent: address, _asset: address) -> bool:
    """
    @notice Adds an asset to an agent's allowed assets
    @dev Can only be called by the owner
    @param _agent The address of the agent
    @param _asset The asset address to add
    @return bool True if the asset was successfully added
    """
    assert msg.sender == self.owner # dev: no perms

    agentInfo: AgentInfo = self.agentSettings[_agent]
    assert agentInfo.isActive # dev: agent not active

    assert _asset != empty(address) # dev: invalid asset
    assert _asset not in agentInfo.allowedAssets # dev: asset already saved

    # save data
    agentInfo.allowedAssets.append(_asset)
    self.agentSettings[_agent] = agentInfo

    # log event
    log AssetAddedToAgent(_agent, _asset)
    return True


# modify allowed actions


@nonreentrant
@external
def modifyAllowedActions(_agent: address, _allowedActions: AllowedActions = empty(AllowedActions)) -> bool:
    assert msg.sender == self.owner # dev: no perms

    agentInfo: AgentInfo = self.agentSettings[_agent]
    assert agentInfo.isActive # dev: agent not active

    agentInfo.allowedActions = _allowedActions
    agentInfo.allowedActions.isSet = self._hasAllowedActionsSet(_allowedActions)
    self.agentSettings[_agent] = agentInfo

    log AllowedActionsModified(_agent, _allowedActions.canDeposit, _allowedActions.canWithdraw, _allowedActions.canRebalance, _allowedActions.canTransfer, _allowedActions.canSwap, _allowedActions.canConvert)
    return True


@view
@internal
def _hasAllowedActionsSet(_actions: AllowedActions) -> bool:
    return _actions.canDeposit or _actions.canWithdraw or _actions.canRebalance or _actions.canTransfer or _actions.canSwap or _actions.canConvert


######################
# Transfer Whitelist #
######################


@nonreentrant
@external
def setWhitelistAddr(_addr: address, _isAllowed: bool) -> bool:
    """
    @notice Sets or removes an address from the transfer whitelist
    @dev Can only be called by the owner
    @param _addr The external address to whitelist/blacklist
    @param _isAllowed Whether the address can receive funds
    @return bool True if the whitelist was updated successfully
    """
    owner: address = self.owner
    assert msg.sender == owner # dev: no perms

    assert _addr != empty(address) # dev: invalid addr
    assert _addr != owner # dev: owner cannot be whitelisted
    assert _addr != self # dev: wallet cannot be whitelisted
    assert _isAllowed != self.isRecipientAllowed[_addr] # dev: already set

    self.isRecipientAllowed[_addr] = _isAllowed
    log WhitelistAddrSet(_addr, _isAllowed)
    return True


##################
# reserve assets #
##################


@nonreentrant
@external
def setReserveAsset(_asset: address, _amount: uint256) -> bool:
    assert msg.sender == self.owner # dev: no perms
    assert _asset != empty(address) # dev: invalid asset
    self.reserveAssets[_asset] = _amount
    log ReserveAssetSet(_asset, _amount)
    return True


@nonreentrant
@external
def setManyReserveAssets(_assets: DynArray[ReserveAsset, MAX_ASSETS]) -> bool:
    assert msg.sender == self.owner # dev: no perms
    assert len(_assets) != 0 # dev: invalid array length
    for i: uint256 in range(len(_assets), bound=MAX_ASSETS):
        asset: address = _assets[i].asset
        amount: uint256 = _assets[i].amount
        assert asset != empty(address) # dev: invalid asset
        self.reserveAssets[asset] = amount
        log ReserveAssetSet(asset, amount)

    return True
