import pytest
import boa

from constants import MAX_UINT256, ZERO_ADDRESS, MIN_INT24, MAX_INT24
from conf_utils import filter_logs
from conf_tokens import TEST_AMOUNTS


@pytest.fixture(scope="package")
def setupWithdrawal(getTokenAndWhale, bob_ai_wallet, bob_agent):
    def setupWithdrawal(_legoId, _token_str, _vaultToken):
        asset, whale = getTokenAndWhale(_token_str)
        asset.transfer(bob_ai_wallet.address, TEST_AMOUNTS[_token_str] * (10 ** asset.decimals()), sender=whale)
        _a, _b, vault_tokens_received, _c = bob_ai_wallet.depositTokens(_legoId, asset.address, _vaultToken, MAX_UINT256, sender=bob_agent)
        return asset, vault_tokens_received

    yield setupWithdrawal


@pytest.fixture(scope="package")
def testLegoDeposit(bob_ai_wallet, bob_agent, lego_registry, _test):
    def testLegoDeposit(
        _legoId,
        _asset,
        _vaultToken,
        _amount = MAX_UINT256,
    ):
        # pre balances
        pre_user_asset_bal = _asset.balanceOf(bob_ai_wallet)
        pre_user_vault_bal = _vaultToken.balanceOf(bob_ai_wallet)

        lego_addr = lego_registry.getLegoAddr(_legoId)
        pre_lego_asset_bal = _asset.balanceOf(lego_addr)
        pre_lego_vault_bal = _vaultToken.balanceOf(lego_addr)

        # deposit
        deposit_amount, vault_token, vault_tokens_received, usd_value = bob_ai_wallet.depositTokens(_legoId, _asset.address, _vaultToken, _amount, sender=bob_agent)

        # event
        log_wallet = filter_logs(bob_ai_wallet, "UserWalletDeposit")[0]
        assert log_wallet.signer == bob_agent
        assert log_wallet.asset == _asset.address
        assert log_wallet.vaultToken == vault_token
        assert log_wallet.assetAmountDeposited == deposit_amount
        assert log_wallet.vaultTokenAmountReceived == vault_tokens_received
        assert log_wallet.usdValue == usd_value
        assert log_wallet.legoId == _legoId
        assert log_wallet.legoAddr == lego_addr
        assert log_wallet.isSignerAgent == True

        assert _vaultToken.address == vault_token
        assert deposit_amount != 0
        assert vault_tokens_received != 0

        if _amount == MAX_UINT256:
            _test(deposit_amount, pre_user_asset_bal)
        else:
            _test(deposit_amount, _amount)

        # lego addr should not have any leftover
        assert _asset.balanceOf(lego_addr) == pre_lego_asset_bal
        assert _vaultToken.balanceOf(lego_addr) == pre_lego_vault_bal

        # vault tokens
        _test(pre_user_vault_bal + vault_tokens_received, _vaultToken.balanceOf(bob_ai_wallet.address))

        # asset amounts
        _test(pre_user_asset_bal - deposit_amount, _asset.balanceOf(bob_ai_wallet.address))


    yield testLegoDeposit


@pytest.fixture(scope="package")
def testLegoWithdrawal(bob_ai_wallet, bob_agent, lego_registry, _test):
    def testLegoWithdrawal(
        _legoId,
        _asset,
        _vaultToken,
        _amount = MAX_UINT256,
    ):
        # pre balances
        pre_user_asset_bal = _asset.balanceOf(bob_ai_wallet)
        pre_user_vault_bal = _vaultToken.balanceOf(bob_ai_wallet)

        lego_addr = lego_registry.getLegoAddr(_legoId)
        pre_lego_asset_bal = _asset.balanceOf(lego_addr)
        pre_lego_vault_bal = _vaultToken.balanceOf(lego_addr)

        # deposit
        amount_received, vault_token_burned, usd_value = bob_ai_wallet.withdrawTokens(_legoId, _asset.address, _vaultToken, _amount, sender=bob_agent)

        # event
        log_wallet = filter_logs(bob_ai_wallet, "UserWalletWithdrawal")[0]
        assert log_wallet.signer == bob_agent
        assert log_wallet.asset == _asset.address
        assert log_wallet.vaultToken == _vaultToken.address
        assert log_wallet.assetAmountReceived == amount_received
        assert log_wallet.vaultTokenAmountBurned == vault_token_burned
        assert log_wallet.legoId == _legoId
        assert log_wallet.legoAddr == lego_addr
        assert log_wallet.isSignerAgent == True
        assert log_wallet.usdValue == usd_value
        assert amount_received != 0
        assert vault_token_burned != 0

        if _amount == MAX_UINT256:
            _test(vault_token_burned, pre_user_vault_bal)
        else:
            _test(vault_token_burned, _amount)

        # lego addr should not have any leftover
        assert _asset.balanceOf(lego_addr) == pre_lego_asset_bal
        assert _vaultToken.balanceOf(lego_addr) == pre_lego_vault_bal

        # vault tokens
        _test(pre_user_vault_bal - vault_token_burned, _vaultToken.balanceOf(bob_ai_wallet.address))

        # asset amounts
        _test(pre_user_asset_bal + amount_received, _asset.balanceOf(bob_ai_wallet.address))

    yield testLegoWithdrawal


@pytest.fixture(scope="package")
def testLegoSwap(bob_ai_wallet, bob_agent, lego_registry, _test):
    def testLegoSwap(
        _legoId,
        _tokenIn,
        _tokenOut,
        _pool,
        _amountIn = MAX_UINT256,
        _minAmountOut = 0,
    ):
        # pre balances
        pre_user_from_bal = _tokenIn.balanceOf(bob_ai_wallet)
        pre_user_to_bal = _tokenOut.balanceOf(bob_ai_wallet)

        lego_addr = lego_registry.getLegoAddr(_legoId)
        pre_lego_from_bal = _tokenIn.balanceOf(lego_addr)
        pre_lego_to_bal = _tokenOut.balanceOf(lego_addr)

        instruction = (
            _legoId,
            _amountIn,
            _minAmountOut,
            [_tokenIn, _tokenOut],
            [_pool]
        )

        # swap
        fromSwapAmount, toAmount, usd_value = bob_ai_wallet.swapTokens([instruction], sender=bob_agent)

        # event
        log_wallet = filter_logs(bob_ai_wallet, "UserWalletSwap")[0]
        assert log_wallet.signer == bob_agent
        assert log_wallet.tokenIn == _tokenIn.address
        assert log_wallet.tokenOut == _tokenOut.address
        assert log_wallet.swapAmount == fromSwapAmount
        assert log_wallet.toAmount == toAmount
        assert log_wallet.numTokens == 2
        assert log_wallet.legoId == _legoId
        assert log_wallet.legoAddr == lego_addr
        assert log_wallet.isSignerAgent == True
        assert log_wallet.usdValue == usd_value

        assert fromSwapAmount != 0
        assert toAmount != 0

        if _amountIn == MAX_UINT256:
            _test(fromSwapAmount, pre_user_from_bal)
        else:
            _test(fromSwapAmount, _amountIn)

        # lego addr should not have any leftover
        assert _tokenIn.balanceOf(lego_addr) == pre_lego_from_bal
        assert _tokenOut.balanceOf(lego_addr) == pre_lego_to_bal

        # to tokens
        _test(pre_user_to_bal + toAmount, _tokenOut.balanceOf(bob_ai_wallet.address))

        # from tokens
        _test(pre_user_from_bal - fromSwapAmount, _tokenIn.balanceOf(bob_ai_wallet.address))

    yield testLegoSwap


@pytest.fixture(scope="package")
def testLegoLiquidityAdded(bob_ai_wallet, bob_agent, _test):
    def testLegoLiquidityAdded(
        _lego,
        _nftAddr,
        _nftTokenId,
        _pool,
        _tokenA,
        _tokenB,
        _amountA = MAX_UINT256,
        _amountB = MAX_UINT256,
        _tickLower = MIN_INT24,
        _tickUpper = MAX_INT24,
        _minAmountA = 0,
        _minAmountB = 0,
    ):
        lp_token_addr = _lego.getLpToken(_pool.address)
        lp_token = lp_token_addr
        if lp_token_addr != ZERO_ADDRESS:
            lp_token = boa.from_etherscan(lp_token_addr)

        # pre balances
        pre_user_bal_a = _tokenA.balanceOf(bob_ai_wallet)
        pre_user_bal_b = _tokenB.balanceOf(bob_ai_wallet)

        pre_nft_bal = 0
        pre_user_lp_bal = 0

        # lp tokens
        if _nftAddr == ZERO_ADDRESS:
            pre_user_lp_bal = lp_token.balanceOf(bob_ai_wallet)

        # nft stuff
        else:
            pre_nft_bal = _nftAddr.balanceOf(bob_ai_wallet)

        pre_lego_bal_a = _tokenA.balanceOf(_lego.address)
        pre_lego_bal_b = _tokenB.balanceOf(_lego.address)

        # add liquidity
        liquidityAdded, liqAmountA, liqAmountB, usdValue, nftTokenId = bob_ai_wallet.addLiquidity(_lego.legoId(), _nftAddr, _nftTokenId, _pool.address, _tokenA.address, _tokenB.address, _amountA, _amountB, _tickLower, _tickUpper, _minAmountA, _minAmountB, sender=bob_agent)

        # event
        log_wallet = filter_logs(bob_ai_wallet, "UserWalletLiquidityAdded")[0]
        assert log_wallet.signer == bob_agent
        assert log_wallet.tokenA == _tokenA.address
        assert log_wallet.tokenB == _tokenB.address
        assert log_wallet.liqAmountA == liqAmountA
        assert log_wallet.liqAmountB == liqAmountB
        assert log_wallet.liquidityAdded == liquidityAdded
        assert log_wallet.pool == _pool.address
        assert log_wallet.usdValue == usdValue
        assert log_wallet.legoId == _lego.legoId()
        assert log_wallet.legoAddr == _lego.address
        assert log_wallet.isSignerAgent == True

        assert liqAmountA != 0 or liqAmountB != 0
        assert liquidityAdded != 0

        # lego addr should not have any leftover
        # rebasing tokens like usdm leaving a little extra
        current_lego_bal_a = _tokenA.balanceOf(_lego.address)
        if current_lego_bal_a <= 5:
            current_lego_bal_a = 0
        assert current_lego_bal_a == pre_lego_bal_a
        current_lego_bal_b = _tokenB.balanceOf(_lego.address)
        if current_lego_bal_b <= 5:
            current_lego_bal_b = 0
        assert current_lego_bal_b == pre_lego_bal_b

        # liq tokens
        _test(pre_user_bal_a - liqAmountA, _tokenA.balanceOf(bob_ai_wallet.address))

        # rebasing tokens like usdm leaving a little extra
        current_user_bal_b = _tokenB.balanceOf(bob_ai_wallet.address)
        if current_user_bal_b <= 5:
            current_user_bal_b = 0
        expected_user_bal_b = pre_user_bal_b - liqAmountB
        if expected_user_bal_b <= 5:
            expected_user_bal_b = 0
        _test(expected_user_bal_b, current_user_bal_b)

        # lp tokens
        if _nftAddr == ZERO_ADDRESS:
            _test(pre_user_lp_bal + liquidityAdded, lp_token.balanceOf(bob_ai_wallet.address))

        # nft stuff
        else:
            assert _nftAddr.balanceOf(_lego.address) == 0

            if _nftTokenId == 0:
                assert _nftAddr.balanceOf(bob_ai_wallet.address) == pre_nft_bal + 1
            else:
                # same nft balance
                assert _nftAddr.balanceOf(bob_ai_wallet.address) == pre_nft_bal

        return nftTokenId

    yield testLegoLiquidityAdded


@pytest.fixture(scope="package")
def testLegoLiquidityRemoved(bob_ai_wallet, bob_agent, _test):
    def testLegoLiquidityRemoved(
        _lego,
        _nftAddr,
        _nftTokenId,
        _pool,
        _tokenA,
        _tokenB,
        _liqToRemove = MAX_UINT256,
        _minAmountA = 0,
        _minAmountB = 0,
    ):
        lp_token_addr = _lego.getLpToken(_pool.address)
        lp_token = lp_token_addr
        if lp_token_addr != ZERO_ADDRESS:
            lp_token = boa.from_etherscan(lp_token_addr)

        tokenAddrB = ZERO_ADDRESS
        if _tokenB != ZERO_ADDRESS:
            tokenAddrB = _tokenB.address

        # pre balances
        pre_user_bal_a = _tokenA.balanceOf(bob_ai_wallet)
        pre_user_bal_b = 0
        if _tokenB != ZERO_ADDRESS:
            pre_user_bal_b = _tokenB.balanceOf(bob_ai_wallet)

        pre_nft_bal = 0
        pre_user_lp_bal = 0

        # lp tokens
        if _nftAddr == ZERO_ADDRESS:
            pre_user_lp_bal = lp_token.balanceOf(bob_ai_wallet)

        # nft stuff
        else:
            pre_nft_bal = _nftAddr.balanceOf(bob_ai_wallet)

        pre_lego_bal_a = _tokenA.balanceOf(_lego.address)
        pre_lego_bal_b = 0
        if _tokenB != ZERO_ADDRESS:
            pre_lego_bal_b = _tokenB.balanceOf(_lego.address)

        # remove liquidity
        removedAmountA, removedAmountB, usdValue, isDepleted = bob_ai_wallet.removeLiquidity(_lego.legoId(), _nftAddr, _nftTokenId, _pool.address, _tokenA.address, tokenAddrB, _liqToRemove, _minAmountA, _minAmountB, sender=bob_agent)

        # event
        log_wallet = filter_logs(bob_ai_wallet, "UserWalletLiquidityRemoved")[0]
        assert log_wallet.signer == bob_agent
        assert log_wallet.tokenA == _tokenA.address
        assert log_wallet.tokenB == tokenAddrB
        assert log_wallet.removedAmountA == removedAmountA
        assert log_wallet.removedAmountB == removedAmountB
        assert log_wallet.usdValue == usdValue
        assert log_wallet.legoId == _lego.legoId()
        assert log_wallet.legoAddr == _lego.address
        assert log_wallet.isSignerAgent == True

        assert removedAmountA != 0 or removedAmountB != 0

        # lego addr should not have any leftover
        assert _tokenA.balanceOf(_lego.address) == pre_lego_bal_a
        if _tokenB != ZERO_ADDRESS:
            assert _tokenB.balanceOf(_lego.address) == pre_lego_bal_b

        # liq tokens
        _test(pre_user_bal_a + removedAmountA, _tokenA.balanceOf(bob_ai_wallet.address))
        if _tokenB != ZERO_ADDRESS:
            _test(pre_user_bal_b + removedAmountB, _tokenB.balanceOf(bob_ai_wallet.address))

        # lp tokens
        if _nftAddr == ZERO_ADDRESS:
            _test(pre_user_lp_bal - log_wallet.liquidityRemoved, lp_token.balanceOf(bob_ai_wallet.address))
            assert log_wallet.lpToken == lp_token_addr

        # nft stuff
        else:
            assert _nftAddr.balanceOf(_lego.address) == 0

            if isDepleted:
                assert _nftAddr.balanceOf(bob_ai_wallet.address) == pre_nft_bal - 1
            else:
                # same nft balance
                assert _nftAddr.balanceOf(bob_ai_wallet.address) == pre_nft_bal


    yield testLegoLiquidityRemoved