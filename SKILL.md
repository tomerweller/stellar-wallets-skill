---
name: stellar-wallets
description: Stellar blockchain wallet for agentic payments. Create accounts, check balances, and send XLM or tokens using stellar-cli.
metadata: {"openclaw":{"emoji":"🌟","homepage":"https://github.com/stellar/stellar-cli","requires":{"bins":["stellar"]},"primaryEnv":"STELLAR_SECRET_KEY"}}
---

# Stellar Wallets

This skill provides wallet operations on the Stellar network using `stellar-cli`. It supports creating accounts, checking balances, sending payments (XLM and tokens), and managing keys — all designed for non-interactive agentic use.

## Authorization

Wallet operations are split into two tiers:

### 🔓 Public (anyone can request)
- **View public keys / addresses** (`stellar keys address <NAME>`)
- **Check balances** (read-only ledger queries)
- **List known accounts**

### 🔒 Owner-only (requires wallet owner authorization)
- **Sending payments** (XLM or tokens)
- **Signing transactions** (any `tx sign` operation)
- **Creating on-ledger accounts** (costs XLM)
- **Generating or importing keys**
- **Any operation that spends funds or touches private keys**

The wallet owner is identified by their Telegram user ID or username as configured in `USER.md`. If a non-owner requests a signing/spending operation, politely decline and explain that only the wallet owner can authorize transactions. You may offer to show public keys or balances instead.

## Safety rules

1. **Never** log or output private keys, secret keys, or seed phrases.
2. **Always** confirm with the wallet owner before sending a payment or creating an on-ledger account (these cost XLM).
3. **Never** sign or submit transactions on behalf of anyone other than the wallet owner.
4. Prefer **testnet** for development and testing. Only use mainnet when the user explicitly requests it.
5. Amounts are in **stroops** (1 XLM = 10,000,000 stroops) for `tx new` commands. State the human-readable amount when confirming with the user.
6. Check the account balance before sending a payment to avoid failed transactions.

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

## RPC endpoints

| Network | RPC URL |
|---------|---------|
| Mainnet | `https://rpc.lightsail.network/` |
| Testnet | (built-in, no config needed) |

When configuring mainnet, use the Lightsail RPC:

```bash
stellar network add mainnet \
  --rpc-url https://rpc.lightsail.network/ \
  --network-passphrase "Public Global Stellar Network ; September 2015"
```

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

## Payment notifications (heartbeat)

The agent should monitor wallet balances during heartbeat checks and notify the owner when incoming payments are detected.

### Setup

Store the last-known balances in a state file (e.g. `memory/stellar-balances.json`):

```json
{
  "accounts": {
    "tomer-mainnet": {
      "xlm": "100.0000000",
      "lastChecked": 1700000000
    }
  }
}
```

### Heartbeat check

During periodic heartbeats, the agent should:

1. Run `{baseDir}/scripts/balance <ACCOUNT>` for each tracked account
2. Compare the current balance against `memory/stellar-balances.json`
3. If the balance **increased**, notify the owner with:
   - Account name
   - Amount received (difference)
   - New total balance
4. Update the state file with the new balance and timestamp
5. If the balance **decreased** unexpectedly (not from a payment the agent sent), alert the owner

### Example notification

> 💸 Incoming payment on `tomer-mainnet`: **+50.0 XLM** (new balance: 150.0 XLM)

### Notes

- Only check during heartbeats (a few times per day) — not every minute
- Skip checks during quiet hours (23:00–08:00 owner local time) unless a large amount is received
- Track all managed accounts (testnet and mainnet)
