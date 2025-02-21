import os


ZERO_ADDRESS = "0x0000000000000000000000000000000000000000"
EIGHTEEN_DECIMALS = 10**18
HUNDRED_PERCENT = 100_00
MAX_UINT256 = 2**256 - 1

# action types

DEPOSIT_INDEX = 0
WITHDRAWAL_INDEX = 1
REBALANCE_INDEX = 2
TRANSFER_INDEX = 3
SWAP_INDEX = 4
CONVERSION_INDEX = 5
ADD_LIQ_INDEX = 6
REMOVE_LIQ_INDEX = 7

DEPOSIT_UINT256 = 2**DEPOSIT_INDEX  # 2 ** 0 = 1
WITHDRAWAL_UINT256 = 2**WITHDRAWAL_INDEX  # 2 ** 1 = 2
REBALANCE_UINT256 = 2**REBALANCE_INDEX  # 2 ** 2 = 4
TRANSFER_UINT256 = 2**TRANSFER_INDEX  # 2 ** 3 = 8
SWAP_UINT256 = 2**SWAP_INDEX  # 2 ** 4 = 16
CONVERSION_UINT256 = 2**CONVERSION_INDEX  # 2 ** 5 = 32
ADD_LIQ_UINT256 = 2**ADD_LIQ_INDEX  # 2 ** 6 = 64
REMOVE_LIQ_UINT256 = 2**REMOVE_LIQ_INDEX  # 2 ** 7 = 128

# lego types

YIELD_OPP_INDEX = 0
DEX_INDEX = 1

YIELD_OPP_UINT256 = 2**YIELD_OPP_INDEX  # 2 ** 0 = 1
DEX_UINT256 = 2**DEX_INDEX  # 2 ** 1 = 2

# time

HOUR_IN_SECONDS = 60 * 60
DAY_IN_SECONDS = 24 * HOUR_IN_SECONDS
WEEK_IN_SECONDS = 7 * DAY_IN_SECONDS
MONTH_IN_SECONDS = 30 * DAY_IN_SECONDS
YEAR_IN_SECONDS = 365 * DAY_IN_SECONDS