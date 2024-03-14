*This repo is a work in progress. Like, nothing in this repo makes sense.*

# RWAs

## Types

3 different setups:

- Asset location
  - On or Off chain
- Collateral location
  - On or Off chain
- Backing type
  - Direct or Indirect (synthetic)

so since we have 3 categories each with 2 options, we have 8 different types of RWAs.

## Examples 

- Onchain asset, onchain collateral, direct backing 
  - Examples: WETH
  - Not demo'd in this repo
- Onchain asset, onchain collateral, indirect backing (synthetic)
  - Examples: WBTC 
  - Not demo'd in this repo
- Onchain asset, offchain collateral, direct backing 
  - Examples: N/A
  - Maybe like a wrapped BTC ETF?
  - Not demo'd in this repo
- Onchain asset, offchain collateral, indirect backing (synthetic)
  - Examples: N/A
  - Maybe like a wrapped BTC ETF that represents an ETH ETF?
  - Not demo'd in this repo
- Offchain asset, onchain collateral, direct backing 
  - Examples: N/A 
  - Like a stablecoin backed by other stablecoins (sort of DAI lmao)
  - Not demo'd in this repo
- Offchain asset, onchain collateral, indirect backing (synthetic)
  - Examples: DAI
  - In this repo: sTSLA w/ chainlink price feeds
- Offchain asset, offchain collateral, direct backing 
  - Examples: USDC
  - In this repo: dTSLA w/ chainlink functions
- Offchain asset, offchain collateral, indirect backing (synthetic)
  - Examples: USDT
  - In this repo: sTSLA w/ chainlink functions

Also in this repo:
- Generalized CCIP setup for the 3 types we demo in this repo. CrossChain functionality will be crucial for RWAs to be useful. 

## Notes for patrick

Alpaca endpoints:
- https://paper-api.alpaca.markets/v2