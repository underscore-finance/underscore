import pytest
import boa

from eth_account import Account
from contracts.core import WalletFunds, WalletConfig
from constants import ZERO_ADDRESS


@pytest.fixture(scope="package")
def ai_wallet(agent_factory, owner, agent):
    w = agent_factory.createAgenticWallet(owner, agent, sender=owner)
    assert w != ZERO_ADDRESS
    assert agent_factory.isAgenticWallet(w)
    return WalletFunds.at(w)


@pytest.fixture(scope="package")
def ai_wallet_config(ai_wallet):
    return WalletConfig.at(ai_wallet.walletConfig())


@pytest.fixture(scope="package")
def signDeposit(agent_signer):
    def signDeposit(
        _wallet,
        _lego_id,
        _asset,
        _vault,
        _amount,
        _expiration=boa.env.evm.patch.timestamp + 60,  # 1 minute
    ):
        # the data to be signed
        message = {
            "domain": {
                "name": "AgenticWallet",
                "version": _wallet.apiVersion(),
                "chainId": boa.env.evm.patch.chain_id,
                "verifyingContract": _wallet.address,
            },
            "types": {
                "Deposit": [
                    {"name": "legoId", "type": "uint256"},
                    {"name": "asset", "type": "address"},
                    {"name": "vault", "type": "address"},
                    {"name": "amount", "type": "uint256"},
                    {"name": "expiration", "type": "uint256"},
                ],
            },
            "message": {
                "legoId": _lego_id,
                "asset": _asset,
                "vault": _vault,
                "amount": _amount,
                "expiration": _expiration,
            }
        }
        return (Account.sign_typed_data(agent_signer.key, full_message=message).signature, agent_signer.address, _expiration)
    yield signDeposit


@pytest.fixture(scope="package")
def signWithdrawal(agent_signer):
    def signWithdrawal(
        _wallet,
        _lego_id,
        _asset,
        _vaultToken,
        _vaultTokenAmount,
        _expiration=boa.env.evm.patch.timestamp + 60,  # 1 minute
    ):
        # the data to be signed
        message = {
            "domain": {
                "name": "AgenticWallet",
                "version": _wallet.apiVersion(),
                "chainId": boa.env.evm.patch.chain_id,
                "verifyingContract": _wallet.address,
            },
            "types": {
                "Withdrawal": [
                    {"name": "legoId", "type": "uint256"},
                    {"name": "asset", "type": "address"},
                    {"name": "vaultToken", "type": "address"},
                    {"name": "vaultTokenAmount", "type": "uint256"},
                    {"name": "expiration", "type": "uint256"},
                ],
            },
            "message": {
                "legoId": _lego_id,
                "asset": _asset,
                "vaultToken": _vaultToken,
                "vaultTokenAmount": _vaultTokenAmount,
                "expiration": _expiration,
            }
        }
        return (Account.sign_typed_data(agent_signer.key, full_message=message).signature, agent_signer.address, _expiration)
    yield signWithdrawal


@pytest.fixture(scope="package")
def signRebalance(agent_signer):
    def signRebalance(
        _wallet,
        _fromLegoId,
        _fromAsset,
        _fromVaultToken,
        _toLegoId,
        _toVault,
        _fromVaultTokenAmount,
        _expiration=boa.env.evm.patch.timestamp + 60,  # 1 minute
    ):
        # the data to be signed
        message = {
            "domain": {
                "name": "AgenticWallet",
                "version": _wallet.apiVersion(),
                "chainId": boa.env.evm.patch.chain_id,
                "verifyingContract": _wallet.address,
            },
            "types": {
                "Rebalance": [
                    {"name": "fromLegoId", "type": "uint256"},
                    {"name": "fromAsset", "type": "address"},
                    {"name": "fromVaultToken", "type": "address"},
                    {"name": "toLegoId", "type": "uint256"},
                    {"name": "toVault", "type": "address"},
                    {"name": "fromVaultTokenAmount", "type": "uint256"},
                    {"name": "expiration", "type": "uint256"},
                ],
            },
            "message": {
                "fromLegoId": _fromLegoId,
                "fromAsset": _fromAsset,
                "fromVaultToken": _fromVaultToken,
                "toLegoId": _toLegoId,
                "toVault": _toVault,
                "fromVaultTokenAmount": _fromVaultTokenAmount,
                "expiration": _expiration,
            }
        }
        return (Account.sign_typed_data(agent_signer.key, full_message=message).signature, agent_signer.address, _expiration)
    yield signRebalance


@pytest.fixture(scope="package")
def signSwap(agent_signer):
    def signSwap(
        _wallet,
        _legoId,
        _tokenIn,
        _tokenOut,
        _amountIn,
        _minAmountOut,
        _expiration=boa.env.evm.patch.timestamp + 60,  # 1 minute
    ):
        # the data to be signed
        message = {
            "domain": {
                "name": "AgenticWallet",
                "version": _wallet.apiVersion(),
                "chainId": boa.env.evm.patch.chain_id,
                "verifyingContract": _wallet.address,
            },
            "types": {
                "Swap": [
                    {"name": "legoId", "type": "uint256"},
                    {"name": "tokenIn", "type": "address"},
                    {"name": "tokenOut", "type": "address"},
                    {"name": "amountIn", "type": "uint256"},
                    {"name": "minAmountOut", "type": "uint256"},
                    {"name": "expiration", "type": "uint256"},
                ],
            },
            "message": {
                "legoId": _legoId,
                "tokenIn": _tokenIn,
                "tokenOut": _tokenOut,
                "amountIn": _amountIn,
                "minAmountOut": _minAmountOut,
                "expiration": _expiration,
            }
        }
        return (Account.sign_typed_data(agent_signer.key, full_message=message).signature, agent_signer.address, _expiration)
    yield signSwap


@pytest.fixture(scope="package")
def signTransfer(agent_signer):
    def signTransfer(
        _wallet,
        _recipient,
        _amount,
        _asset,
        _expiration=boa.env.evm.patch.timestamp + 60,  # 1 minute
    ):
        # the data to be signed
        message = {
            "domain": {
                "name": "AgenticWallet",
                "version": _wallet.apiVersion(),
                "chainId": boa.env.evm.patch.chain_id,
                "verifyingContract": _wallet.address,
            },
            "types": {
                "Transfer": [
                    {"name": "recipient", "type": "address"},
                    {"name": "amount", "type": "uint256"},
                    {"name": "asset", "type": "address"},
                    {"name": "expiration", "type": "uint256"},
                ],
            },
            "message": {
                "recipient": _recipient,
                "amount": _amount,
                "asset": _asset,
                "expiration": _expiration,
            }
        }
        return (Account.sign_typed_data(agent_signer.key, full_message=message).signature, agent_signer.address, _expiration)
    yield signTransfer