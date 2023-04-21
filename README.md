# Hermitian

Contracts for Hermitian - a middleware for credible squaring

## Contracts

```ml
├─ DisputeResolution — "Contract for raising challenges to a specific task and resolving them"
├─ Registration — "Contract for registering, deregistering, and checking past/present status operators"
├─ Task — "Contracts for publishing tasks, submitting responses and storing potential responses"
```

## Usage

You will need a copy of [Foundry](https://github.com/foundry-rs/foundry) installed before proceeding. See the [installation guide](https://github.com/foundry-rs/foundry#installation) for details.

To build the contracts:

```sh
git clone https://github.com/aroralanuk/hermitian-contracts.git
cd hermitian-contracts
forge install
```

### Run Tests

In order to run unit tests, run:

```sh
forge test -vvv
```
