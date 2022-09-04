all: clean upgrade yarn-install build test snapshot format

clean  :; forge clean

upgrade :; foundryup

yarn-install :; yarn install

build:; forge build

test :; forge test

snapshot :; forge snapshot

format :; yarn prettier --write src/ test/

slither :; slither src/

anvil :; anvil -m 'test test test test test test test test test test test junk'

# use the "@" to hide the command from your shell
deploy-rinkeby :; @forge script script/${contract}.s.sol:Deploy${contract} --rpc-url ${RINKEBY_RPC_URL}  --private-key ${PRIVATE_KEY} --broadcast --verify --etherscan-api-key ${ETHERSCAN_API_KEY}  -vvvv

# This is the private key of account from the mnemonic from the "make anvil" command
deploy-anvil :; @forge script script/${contract}.s.sol:Deploy${contract} --rpc-url http://localhost:8545  --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --broadcast
