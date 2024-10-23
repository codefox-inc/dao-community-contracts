-include .env

.PHONY: all test clean deploy fund help install snapshot format anvil scopefile

all: remove install build

clean  :; forge clean

remove :; rm -rf .gitmodules && rm -rf .git/modules/* && rm -rf lib && touch .gitmodules && git add . && git commit -m "modules"

install :; forge install foundry-rs/forge-std@v1.9.2 --no-commit && forge install openzeppelin/openzeppelin-contracts@v5.0.2 --no-commit && forge install OpenZeppelin/openzeppelin-foundry-upgrades@v0.3.2 --no-commit && forge install OpenZeppelin/openzeppelin-contracts-upgradeable@v5.0.2 --no-commit

# Update Dependencies
update:; forge update

build:; forge build

test :; forge test --no-match-path "test/onChain/*.sol"

snapshot :; forge snapshot

format :; forge fmt

coverage :; forge coverage --no-match-path "test/onChain/*.sol"

coverage-report :; forge coverage --report debug > coverage-report.txt --no-match-path "test/onChain/*.sol"

NETWORK_ARGS := --rpc-url http://localhost:8545 --private-key $(DEFAULT_ANVIL_KEY) --broadcast

ifeq ($(findstring --network sepolia,$(ARGS)),--network sepolia)
	NETWORK_ARGS := --rpc-url $(SEPOLIA_RPC_URL) --private-key $(PRIVATE_KEY_DEPLOYER) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv
endif

ifeq ($(findstring --network basesepolia,$(ARGS)),--network basesepolia)
	NETWORK_ARGS := --rpc-url $(BASE_SEPOLIA_RPC_URL) --private-key $(PRIVATE_KEY_DEPLOYER) --broadcast --verify --etherscan-api-key $(BASE_API_KEY) -vvvv
endif

ifeq ($(findstring --network basemainnet,$(ARGS)),--network basemainnet)
	NETWORK_ARGS := --rpc-url $(BASE_MAINNET_RPC_URL) --private-key $(PRIVATE_KEY_DEPLOYER) --broadcast --verify --etherscan-api-key $(BASE_API_KEY) -vvvv
endif

deploy:
	@forge clean && forge script script/DeployContracts.s.sol:DeployContracts $(NETWORK_ARGS)

deploy-nft:
	@forge clean && forge script script/DeployNft.s.sol:DeployNft $(NETWORK_ARGS)
