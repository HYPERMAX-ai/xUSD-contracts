# xUSD

`xUSD.sol`

ERC20 stablecoin that can be:
- minted by the owner as protocol debt (`mint`)
- burned to repay that debt (`burn`)
- minted 1-for-1 against any whitelisted collateral via the PSM (`psmDeposit`)
- redeemed back to collateral by addresses on a redemption whitelist (`psmRedeem`)

The contract also exposes:
- `addAsset` / `allowedAsset` manage the list of collateral tokens
- `addWhitelist` / `removeWhitelist` gate redemptions
- `totalSupply()` override returns circulating supply (base supply minus totalDebt)

<!-- ---

# Known issues

### unlimited debt

The owner can create unlimited un-backed xUSD; there is no supply cap. -->
