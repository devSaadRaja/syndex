# Syndex

Trade Synthetic perpetuals.

Gain exposure to an entirely new class of assets with up to 100x leverage, deep liquidity and near zero slippage.

# 

To get started we need to install the foundry package which requires rust. Here are the commands for linux, mac, and windows.

### Linux/Mac:

```shell
$ curl -L https://foundry.paradigm.xyz | bash;
$ foundryup
```

### Windows: (Requires Rust, install from https://rustup.rs/)

```shell
$ cargo install --git https://github.com/foundry-rs/foundry --bins --locked
```

# 

## Start the project

### Install

```shell
$ forge install
```

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Mainnet Test

```shell
$ forge test --fork-url "<your_rpc_url>" --match-path test/SMX.t.sol -vv
```

### Deploy

```shell
$ forge create --rpc-url "<your_rpc_url>" --private-key "<your_private_key>" <filePath> --constructor-args <> --etherscan-api-key <> --verify
or
$ forge script script/Deploy.s.sol:DeployScript --rpc-url "<your_rpc_url>" --private-key "<your_private_key>"
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
