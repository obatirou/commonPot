all: clean upgrade yarn-install build test snapshot format

clean  :; forge clean

upgrade :; foundryup

yarn-install :; yarn install

build:; forge build

test :; forge test

snapshot :; forge snapshot

format :; yarn prettier --write src/ test/