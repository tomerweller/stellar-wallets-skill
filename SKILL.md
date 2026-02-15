---
name: stellar-wallets
description: Stellar blockchain wallet for agentic payments. Create accounts, check balances, and send XLM or tokens using stellar-cli.
metadata: {"openclaw":{"emoji":"🌟","homepage":"https://github.com/stellar/stellar-cli","requires":{"bins":["stellar"]},"primaryEnv":"STELLAR_SECRET_KEY"}}
---

# Stellar Wallets

This skill provides wallet operations on the Stellar network using `stellar-cli`. It supports creating accounts, checking balances, sending payments (XLM and tokens), and managing keys — all designed for non-interactive agentic use.

## Safety rules

1. **Never** log or output private keys, secret keys, or seed phrases.
2. **Always** confirm with the user before sending a payment or creating an on-ledger account (these cost XLM).
3. Prefer **testnet** for development and testing. Only use mainnet when the user explicitly requests it.
4. Amounts are in **stroops** (1 XLM = 10,000,000 stroops) for `tx new` commands. State the human-readable amount when confirming with the user.
5. Check the account balance before sending a payment to avoid failed transactions.

## Environment variables

Required for signing transactions:
- `STELLAR_SECRET_KEY` — secret key (S...) or seed phrase for the default identity

Required for network access:
- `STELLAR_NETWORK` — network name (`testnet` or `mainnet`)

Optional:
- `STELLAR_ACCOUNT` — default source account alias or public key
- `STELLAR_RPC_URL` — custom RPC endpoint
- `STELLAR_NETWORK_PASSPHRASE` — network passphrase (set automatically when using named networks)
- `STELLAR_INCLUSION_FEE` — default fee in stroops (default: 100)

## One-time setup

If `stellar` is not on PATH, run the bootstrap script:

```bash
{baseDir}/bootstrap.sh
```

Then configure the network:

```bash
stellar network use testnet
```

## Key management

### Generate a new identity

```bash
stellar keys generate <NAME>
```

Creates a keypair and stores it locally under the alias. Add `--fund` on testnet to fund it via friendbot:

```bash
stellar keys generate <NAME> --fund --network testnet
```

### Import an existing key (non-interactive)

```bash
STELLAR_SECRET_KEY=<SECRET_KEY> stellar keys add <NAME>
```

The `STELLAR_SECRET_KEY` environment variable bypasses the interactive secret prompt.

### Get the public address

```bash
stellar keys address <NAME>
```

**Output:** a Stellar public key (G...).

### Set the default identity

```bash
stellar keys use <NAME>
```

Or set `STELLAR_ACCOUNT=<NAME>` in the environment.

### Fund on testnet

```bash
stellar keys fund <NAME>
```

## Check balance

### Fetch account entry

```bash
stellar ledger entry fetch account --account <NAME_OR_ADDRESS> --output json-formatted
```

**Output:** JSON object. The `balance` field is the XLM balance in stroops.

Parse the balance:

```bash
{baseDir}/scripts/balance <NAME_OR_ADDRESS>
```

**Output:**
```json
{"address": "GABC...", "xlm": "100.0000000", "stroops": 1000000000}
```

### Check token balance (Soroban asset contract)

First resolve the asset contract ID:

```bash
stellar contract id asset --asset native
```

Then query:

```bash
stellar contract invoke --id <CONTRACT_ID> -- balance --id <NAME_OR_ADDRESS>
```

## Send payments

### Send XLM

```bash
stellar tx new payment \
  --source <SENDER> \
  --destination <RECIPIENT> \
  --asset native \
  --amount <STROOPS>
```

Amount is in stroops. For example, to send 5 XLM:

```bash
stellar tx new payment \
  --source alice \
  --destination GABC...DEF \
  --asset native \
  --amount 50000000
```

Use the wrapper for human-readable amounts:

```bash
{baseDir}/scripts/pay <SENDER> <RECIPIENT> <AMOUNT_XLM>
```

**Output:**
```json
{"success": true, "tx_hash": "abc123...", "from": "GABC...", "to": "GDEF...", "amount": "5.0", "asset": "XLM"}
```

On error:
```json
{"success": false, "error": {"code": "insufficient_balance", "message": "Sender balance 2.0 XLM is less than 5.0 XLM"}}
```

### Send a custom asset

```bash
stellar tx new payment \
  --source <SENDER> \
  --destination <RECIPIENT> \
  --asset <CODE>:<ISSUER> \
  --amount <STROOPS>
```

### Send via Soroban token contract

```bash
stellar contract invoke \
  --id <TOKEN_CONTRACT_ID> \
  --source <SENDER> \
  -- transfer \
  --from <SENDER> \
  --to <RECIPIENT> \
  --amount <AMOUNT>
```

## Create accounts

Create and fund a new on-ledger account (costs XLM from the source):

```bash
stellar tx new create-account \
  --source <FUNDER> \
  --destination <NEW_ACCOUNT> \
  --starting-balance <STROOPS>
```

Default starting balance is 10,000,000 stroops (1 XLM).

## Build-sign-send workflow

For advanced flows (multi-sig, offline signing), split the transaction lifecycle:

```bash
# Build
stellar tx new payment \
  --source alice \
  --destination bob \
  --amount 50000000 \
  --build-only \
| stellar tx sign --sign-with-key alice \
| stellar tx send
```

`--build-only` outputs unsigned base64 XDR to stdout.
`tx sign` reads from stdin and outputs signed XDR.
`tx send` reads from stdin, submits, and outputs JSON with the transaction response.

## Agent integration notes

- **Exit codes**: 0 = success, 1 = failure. Errors go to stderr, results to stdout.
- **Quiet mode**: Use `--quiet` to suppress informational stderr output (emoji status lines, explorer links).
- **JSON output**: Use `--output json` on commands that support it: `ledger entry fetch`, `ledger latest`, `events`, `fee-stats`.
- **Never use** `--sign-with-ledger` or `--sign-with-lab` — these require physical device interaction or open a browser.
- **Always use** `--sign-with-key <NAME>` or set `STELLAR_ACCOUNT` for non-interactive signing.

## Troubleshooting

### stellar not found

Run the bootstrap script:

```bash
{baseDir}/bootstrap.sh
```

### Network not configured

```bash
stellar network use testnet
```

Or set environment variables:

```bash
export STELLAR_NETWORK=testnet
```

### Account not funded

On testnet, use friendbot:

```bash
stellar keys fund <NAME>
```

On mainnet, another account must send XLM via `tx new create-account`.
