# stellar-wallets

An [OpenClaw](https://openclaw.ai) skill that gives AI agents wallet operations on the [Stellar](https://stellar.org) network. Create accounts, check balances, and send XLM or tokens — all through [stellar-cli](https://github.com/stellar/stellar-cli).

## Install

```sh
clawhub install stellar-wallets
```

Or manually copy this directory into your OpenClaw skills folder:

```sh
cp -r stellar-wallets-skill ~/.openclaw/skills/stellar-wallets
```

### Prerequisites

- [stellar-cli](https://github.com/stellar/stellar-cli) on PATH (the bootstrap script can install it for you)
- `python3` (used by the wrapper scripts for stroop/XLM conversion)

## Setup

1. **Install stellar-cli** (if not already present):

```sh
./bootstrap.sh
```

2. **Configure the network:**

```sh
stellar network use testnet   # for development
stellar network use mainnet   # for production
```

3. **Create or import a key:**

```sh
# Generate a new keypair
stellar keys generate myagent --fund --network testnet

# Or import an existing secret key (non-interactive)
STELLAR_SECRET_KEY=SC36... stellar keys add myagent
```

4. **Set the default identity:**

```sh
stellar keys use myagent
```

## What the agent can do

| Operation | Command |
|-----------|---------|
| Generate a keypair | `stellar keys generate <name>` |
| Get public address | `stellar keys address <name>` |
| Check XLM balance | `scripts/balance <name>` |
| Send XLM | `scripts/pay <from> <to> <amount_xlm>` |
| Send custom asset | `scripts/pay <from> <to> <amount> --asset CODE:ISSUER` |
| Create account | `stellar tx new create-account --source <funder> --destination <dest>` |
| Fund on testnet | `stellar keys fund <name>` |

## Wrapper scripts

The skill includes wrapper scripts that accept human-readable amounts and return structured JSON, making them easier for agents to use than raw stellar-cli.

### `scripts/balance`

```sh
$ scripts/balance alice
{"success": true, "address": "GABC...", "xlm": "100.0000000", "stroops": 1000000000}
```

### `scripts/pay`

```sh
$ scripts/pay alice bob 5.0
{"success": true, "from": "GABC...", "to": "GDEF...", "amount": "5.0", "asset": "XLM", "stroops": 50000000}
```

On error:

```json
{"success": false, "error": {"code": "tx_failed", "message": "..."}}
```

## Environment variables

| Variable | Required | Description |
|----------|----------|-------------|
| `STELLAR_SECRET_KEY` | For signing | Secret key or seed phrase |
| `STELLAR_NETWORK` | For network access | `testnet` or `mainnet` |
| `STELLAR_ACCOUNT` | Optional | Default source account alias |
| `STELLAR_RPC_URL` | Optional | Custom RPC endpoint |
| `STELLAR_INCLUSION_FEE` | Optional | Fee in stroops (default: 100) |

## File structure

```
stellar-wallets-skill/
├── SKILL.md           # OpenClaw skill definition
├── bootstrap.sh       # Installs stellar-cli
├── README.md
└── scripts/
    ├── balance        # Check XLM balance → JSON
    └── pay            # Send payment → JSON
```

## Safety

- The skill instructs agents to **never** output private keys or seed phrases.
- Agents **must confirm** with the user before sending payments or creating accounts.
- Testnet is preferred by default; mainnet requires explicit user request.
- Wrapper scripts check balances and validate amounts before submitting transactions.

## License

Apache-2.0
