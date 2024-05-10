-include .env

.PHONY: all test clean deploy fund help install snapshot format anvil scopefile deploy-bridges

DEFAULT_ANVIL_KEY := 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

all: remove install build

# Clean the repo
clean  :; forge clean

# Remove modules
remove :; rm -rf .gitmodules && rm -rf .git/modules/* && rm -rf lib && touch .gitmodules && git add . && git commit -m "modules"

install :; forge install cyfrin/foundry-devops --no-commit && forge install smartcontractkit/chainlink-brownie-contracts@0.8.0 --no-commit && forge install foundry-rs/forge-std --no-commit && forge install openzeppelin/openzeppelin-contracts --no-commit && forge install cyfrin/ccip-contracts@1.4.0 --no-commit

# Update Dependencies
update:; forge update

build:; forge build

test :; forge test 

snapshot :; forge snapshot

format :; forge fmt

anvil :; anvil -m 'test test test test test test test test test test test junk' --steps-tracing --block-time 1

slither :; slither . --config-file slither.config.json --checklist 

scope :; tree ./src/ | sed 's/└/#/g; s/──/--/g; s/├/#/g; s/│ /|/g; s/│/|/g'

scopefile :; @tree ./src/ | sed 's/└/#/g' | awk -F '── ' '!/\.sol$$/ { path[int((length($$0) - length($$2))/2)] = $$2; next } { p = "src"; for(i=2; i<=int((length($$0) - length($$2))/2); i++) if (path[i] != "") p = p "/" path[i]; print p "/" $$2; }' > scope.txt

aderyn :; aderyn . 

simulate :; npm run simulate 

getweth :; cast call TOKEN_BRIDGE_ADDRESS "getWeth()" --rpc-url ${SEPOLIA_RPC_URL} | cut -c 27- | xargs printf "0x%s\n" | cast --to-checksum-address 

setSupportedChain-mumbai :; cast send TOKEN_BRIDGE_ADDRESS "setSupportedChain(uint64,bool)" 16015286601757825753 true  --rpc-url ${MUMBAI_RPC_URL} --account XXX --sender YYY
setSupportedChain-sepolia :; cast send TOKEN_BRIDGE_ADDRESS "setSupportedChain(uint64,bool)" 12532609583862916517 true --rpc-url ${SEPOLIA_RPC_URL} --account XXX --sender YYY

# Multi-chain deploymetn doesn't work with account/sender yet :/ 
deploy-bridges :; forge script script/DeployTokenBridges.s.sol --private-key ${PRIVATE_KEY} --verify --broadcast
