import pytest
import boa

from constants import ZERO_ADDRESS, YIELD_OPP_UINT256
from contracts.core.templates import UserWalletTemplate, UserWalletConfigTemplate


# accounts


@pytest.fixture(scope="session")
def deploy3r(env):
    return env.eoa


@pytest.fixture(scope="session")
def owner(env):
    return env.generate_address("owner")


@pytest.fixture(scope="session")
def governor(env):
    return env.generate_address("governor")


@pytest.fixture(scope="session")
def sally(env):
    return env.generate_address("sally")


@pytest.fixture(scope="session")
def bob(env):
    return env.generate_address("bob")


@pytest.fixture(scope="session")
def broadcaster(env):
    return env.generate_address("broadcaster")


@pytest.fixture(scope="session")
def agent(governor):
    # needs to be a contract
    return boa.load("contracts/mock/MockErc20.vy", governor, "Agent", "AGENT", 18, 10_000_000, name="agent")


@pytest.fixture(scope="session")
def bob_agent(bob_agent_dev, agent_factory):
    w = agent_factory.createAgent(bob_agent_dev, sender=bob_agent_dev)
    assert w != ZERO_ADDRESS
    assert agent_factory.isAgent(w)
    return w


@pytest.fixture(scope="session")
def bob_agent_dev(env):
    return env.generate_address("bob_agent_dev")


# agentic wallets 


@pytest.fixture(scope="package")
def bob_ai_wallet(agent_factory, bob, bob_agent, ambassador):
    w = agent_factory.createUserWallet(bob, ambassador, sender=bob)
    assert w != ZERO_ADDRESS
    assert agent_factory.isUserWallet(w)
    wallet = UserWalletTemplate.at(w)
    w_config = UserWalletConfigTemplate.at(wallet.walletConfig())
    w_config.addOrModifyAgent(bob_agent, sender=bob)
    return wallet


@pytest.fixture(scope="package")
def ambassador(agent_factory, owner):
    w = agent_factory.createUserWallet(owner, sender=owner)
    assert w != ZERO_ADDRESS
    assert agent_factory.isUserWallet(w)
    return UserWalletTemplate.at(w)


@pytest.fixture(scope="package")
def bob_ai_wallet_config(bob_ai_wallet):
    return UserWalletConfigTemplate.at(bob_ai_wallet.walletConfig())


# mock asset: alpha token


@pytest.fixture(scope="session")
def alpha_token(governor):
    return boa.load("contracts/mock/MockErc20.vy", governor, "Alpha Token", "ALPHA", 18, 10_000_000, name="alpha_token")


@pytest.fixture(scope="session")
def alpha_token_whale(env, alpha_token, governor):
    whale = env.generate_address("alpha_token_whale")
    alpha_token.mint(whale, 1_000_000 * (10 ** alpha_token.decimals()), sender=governor)
    return whale


@pytest.fixture(scope="session")
def alpha_token_erc4626_vault(alpha_token):
    return boa.load("contracts/mock/MockErc4626Vault.vy", alpha_token, name="alpha_erc4626_vault")


@pytest.fixture(scope="session")
def alpha_token_erc4626_vault_another(alpha_token):
    return boa.load("contracts/mock/MockErc4626Vault.vy", alpha_token, name="alpha_erc4626_vault_another")


@pytest.fixture(scope="session")
def alpha_token_comp_vault(alpha_token):
    return boa.load("contracts/mock/MockCompVault.vy", alpha_token, name="alpha_comp_vault")


# mock asset: bravo token


@pytest.fixture(scope="session")
def bravo_token(governor):
    return boa.load("contracts/mock/MockErc20.vy", governor, "Bravo Token", "BRAVO", 18, 10_000_000, name="bravo_token")


@pytest.fixture(scope="session")
def bravo_token_whale(env, bravo_token, governor):
    whale = env.generate_address("bravo_token_whale")
    bravo_token.mint(whale, 1_000_000 * (10 ** bravo_token.decimals()), sender=governor)
    return whale


@pytest.fixture(scope="session")
def bravo_token_erc4626_vault(bravo_token):
    return boa.load("contracts/mock/MockErc4626Vault.vy", bravo_token, name="bravo_erc4626_vault")


@pytest.fixture(scope="session")
def bravo_token_erc4626_vault_another(bravo_token):
    return boa.load("contracts/mock/MockErc4626Vault.vy", bravo_token, name="bravo_erc4626_vault_another")


# mock asset: charlie token (6 decimals)


@pytest.fixture(scope="session")
def charlie_token(governor):
    return boa.load("contracts/mock/MockErc20.vy", governor, "Charlie Token", "CHARLIE", 6, 10_000_000, name="charlie_token")


@pytest.fixture(scope="session")
def charlie_token_erc4626_vault(charlie_token):
    return boa.load("contracts/mock/MockErc4626Vault.vy", charlie_token, name="charlie_erc4626_vault")


@pytest.fixture(scope="session")
def charlie_token_whale(env, charlie_token, governor):
    whale = env.generate_address("charlie_token_whale")
    charlie_token.mint(whale, 1_000_000 * (10 ** charlie_token.decimals()), sender=governor)
    return whale


# mock asset: weth


@pytest.fixture(scope="session")
def mock_weth():
    return boa.load("contracts/mock/MockWeth.vy", name="mock_weth")


# mock lego


@pytest.fixture(scope="session")
def mock_lego_alpha(alpha_token, alpha_token_erc4626_vault, lego_registry, addy_registry_deploy, governor):
    addr = boa.load("contracts/mock/MockLego.vy", addy_registry_deploy, name="mock_lego_alpha")
    assert addr.addAssetOpportunity(alpha_token, alpha_token_erc4626_vault, sender=governor)
    assert lego_registry.registerNewLego(addr, "Mock Lego Alpha", YIELD_OPP_UINT256, sender=governor)
    boa.env.time_travel(blocks=lego_registry.legoChangeDelay() + 1)
    assert lego_registry.confirmNewLegoRegistration(addr, sender=governor) != 0
    return addr


@pytest.fixture(scope="session")
def mock_lego_alpha_another(alpha_token, alpha_token_erc4626_vault_another, lego_registry, addy_registry_deploy, governor):
    addr = boa.load("contracts/mock/MockLego.vy", addy_registry_deploy, name="mock_lego_alpha_another")
    assert addr.addAssetOpportunity(alpha_token, alpha_token_erc4626_vault_another, sender=governor)
    assert lego_registry.registerNewLego(addr, "Mock Lego Alpha Another", YIELD_OPP_UINT256, sender=governor)
    boa.env.time_travel(blocks=lego_registry.legoChangeDelay() + 1)
    assert lego_registry.confirmNewLegoRegistration(addr, sender=governor) != 0
    return addr


# mock lego: another


@pytest.fixture(scope="session")
def mock_lego_bravo(bravo_token, bravo_token_erc4626_vault, addy_registry_deploy, lego_registry, governor):
    addr = boa.load("contracts/mock/MockLego.vy", addy_registry_deploy, name="mock_lego_bravo")
    assert addr.addAssetOpportunity(bravo_token, bravo_token_erc4626_vault, sender=governor)
    assert lego_registry.registerNewLego(addr, "Mock Lego Bravo", YIELD_OPP_UINT256, sender=governor)
    boa.env.time_travel(blocks=lego_registry.legoChangeDelay() + 1)
    assert lego_registry.confirmNewLegoRegistration(addr, sender=governor) != 0
    return addr


# mock lego: charlie

@pytest.fixture(scope="session")
def mock_lego_charlie(charlie_token, charlie_token_erc4626_vault, addy_registry_deploy, lego_registry, governor):
    addr = boa.load("contracts/mock/MockLego.vy", addy_registry_deploy, name="mock_lego_charlie")
    assert lego_registry.registerNewLego(addr, "Mock Lego Charlie", YIELD_OPP_UINT256, sender=governor)
    boa.env.time_travel(blocks=lego_registry.legoChangeDelay() + 1)
    assert lego_registry.confirmNewLegoRegistration(addr, sender=governor) != 0
    return addr


# mock lego integrations


@pytest.fixture(scope="session")
def mock_registry(alpha_token_erc4626_vault, alpha_token_comp_vault):
    return boa.load("contracts/mock/MockRegistry.vy", [alpha_token_erc4626_vault, alpha_token_comp_vault], name="mock_registry")


@pytest.fixture(scope="session")
def mock_aave_v3_pool():
    return boa.load("contracts/mock/MockAaveV3Pool.vy", name="mock_aave_v3_pool")


# mock pyth / stork


@pytest.fixture(scope="session")
def mock_pyth():
    return boa.load("contracts/mock/MockPyth.vy", name="mock_pyth")


@pytest.fixture(scope="session")
def mock_stork():
    return boa.load("contracts/mock/MockStork.vy", name="mock_stork")


@pytest.fixture
def weth_erc4626_vault(mock_weth):
    """Returns a mock ERC4626 vault for WETH"""
    addr = boa.load("contracts/mock/MockErc4626Vault.vy", mock_weth.address, name="weth_erc4626_vault")
    return addr