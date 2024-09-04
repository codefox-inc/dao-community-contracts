-include .env

.PHONY: all test clean deploy fund help install snapshot format anvil scopefile

all: remove install build

clean  :; forge clean

remove :; rm -rf .gitmodules && rm -rf .git/modules/* && rm -rf lib && touch .gitmodules && git add . && git commit -m "modules"

install :; forge install foundry-rs/forge-std@v1.9.2 --no-commit && forge install openzeppelin/openzeppelin-contracts@v5.0.2 --no-commit && forge install OpenZeppelin/openzeppelin-foundry-upgrades@v0.3.2 --no-commit && forge install OpenZeppelin/openzeppelin-contracts-upgradeable@v5.0.2 --no-commit

# Update Dependencies
update:; forge update

build:; forge build

test :; forge test -vv

snapshot :; forge snapshot

format :; forge fmt
