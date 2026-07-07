#!/usr/bin/env bash
# inject_test_sms.sh
#
# Injects 50 test SMS messages into the Android SMS inbox via adb content insert.
# Works on both emulators and real devices (unlike `adb emu sms send`).
# Requires: adb in PATH, device/emulator connected with USB debugging enabled.
#
# Usage: bash scripts/inject_test_sms.sh
# Then open the TestSMS tab in the Fynans app to see parsed results.

set -euo pipefail

# ── Sanity checks ────────────────────────────────────────────────────────────
if ! command -v adb &>/dev/null; then
  echo "ERROR: adb not found. Add Android SDK platform-tools to PATH."
  exit 1
fi
if ! adb get-state &>/dev/null; then
  echo "ERROR: No device/emulator connected. Connect a device or start an emulator first."
  exit 1
fi

# Timestamp base: 2 days ago in ms (safely within the 7-day window ReadSmsService uses)
BASE_TS=$(( ($(date +%s) - 172800) * 1000 ))

sms() {
  local sender="$1"
  local body="$2"
  local ts=$(( BASE_TS + RANDOM * 60000 ))   # spread messages a few minutes apart
  # The entire command must be a single string so the remote Android shell
  # treats the body value (which contains spaces) as one argument.
  adb shell "content insert \
    --uri content://sms/inbox \
    --bind 'address:s:${sender}' \
    --bind 'body:s:${body}' \
    --bind 'date:l:${ts}' \
    --bind 'date_sent:l:${ts}' \
    --bind 'read:i:0' \
    --bind 'type:i:1'"
  echo "  ✓ [$sender] ${body:0:60}..."
}

echo ""
echo "══════════════════════════════════════════════════════════════"
echo "  Fynans SMS Test Suite — 50 messages"
echo "══════════════════════════════════════════════════════════════"
echo ""

# ── A: Standard debit — should parse as DEBIT ────────────────────────────────
echo "▸ Category A: Standard debits (expect: DEBIT)"

# A01 — Rs. prefix, 'at' merchant, Avl Bal
sms "HDFCBK" "Rs.850.00 debited from A/c XX4521 at SWIGGY on 22-05-26. Avl Bal Rs.12,340.50. Call 1800XXX for dispute."

# A02 — INR prefix, UPI ID as merchant (UPI takes priority over keyword)
sms "ICICI" "INR 320.00 spent via UPI. UPI Ref: 123456789012. To merchant@paytm. A/c XX7890. Avl Bal INR 8,200.00"

# A03 — Indian comma format (1,00,000.00), 'paid to', account in text
sms "KOTAK" "Rs.1,00,000.00 paid to HDFC HOME LOAN EMI. A/c XX3344. Balance Rs.2,45,600.00"

# A04 — Amount in lakhs, 'payment made'
sms "HDFCBK" "Payment made of Rs.2.5 lakh from A/c XX9988 to VENDOR. New Bal Rs.50,000.00"

# A05 — ATM withdrawal, no merchant (amount + balance only)
sms "SBIUPI" "Rs.5,000.00 withdrawn from A/c XX1122 at ATM. Avl Bal Rs.1,234.56"

# A06 — EMI debited keyword
sms "HDFCBK" "EMI debited Rs.12,500.00 from A/c XX6677 for CAR LOAN. Avl Bal Rs.67,890.00"

# A07 — Fee deducted
sms "ICICI" "Annual fee deducted Rs.999.00 from A/c XX5566. Avl Bal Rs.23,100.00. Charges applied."

# A08 — 'transferred' keyword, credit of salary would be sent separately
sms "AIRBNK" "Rs.15,000.00 transferred from A/c XX4433 to VENDOR1234. Avl Bal Rs.5,500.75"

# A09 — Amount suffix format: number BEFORE currency symbol
sms "HDFCBK" "25000 INR debited from A/c XX2211 for NEFT to BENEFICIARY. Bal Rs.1,10,000.00"

# A10 — 'paid to' with UPI ID
sms "BOBSMS" "Rs.199.00 paid to netflix@hdfc via UPI from A/c XX8877. Bal Rs.4,321.00"

# A11 — 'purchase at' with card number (not account), multi-word merchant
sms "KOTAK" "Rs.4,599.00 purchase at AMAZON INDIA using Card XX4321. Avl Bal Rs.32,100.00"

# A12 — 'deducted' for service charge, no merchant keyword match
sms "CENTBK" "Rs.50.00 deducted as SMS charges from A/c XX1010. Updated Bal Rs.7,800.00"

# A13 — 'charged' keyword, annual renewal
sms "HDFCBK" "Rs.2,500.00 charged for Prime Renewal to A/c XX5544. Avl Bal Rs.18,000.50"

# A14 — 'paying' keyword, subscription
sms "ICICI" "You are paying Rs.649.00 to SPOTIFY INDIA from A/c XX3322. Avl Bal Rs.9,900.00"

# A15 — 'sent' keyword (short), to beneficiary name
sms "PAYZAP" "Rs.500.00 sent to RAHUL SHARMA via UPI from A/c XX7711. Bal Rs.2,000.00"

# ── B: Credit messages — should parse as CREDIT ──────────────────────────────
echo ""
echo "▸ Category B: Credits (expect: CREDIT)"

# B16 — 'credited' with 'by' merchant
sms "HDFCBK" "Rs.85,000.00 credited to A/c XX4521 by EMPLOYER PRIVATE LTD on 01-05-26. Bal Rs.97,340.50"

# B17 — 'received from' with UPI ID
sms "ICICI" "INR 250.00 received from friend@okicici via UPI. A/c XX7890. Avl Bal INR 8,450.00"

# B18 — 'deposited' salary credit
sms "SBIUPI" "Rs.55,000.00 deposited to A/c XX1122 by SALARY TRANSFER on 01-05-26. Avl Bal Rs.60,000.00"

# B19 — 'refund' from e-commerce
sms "HDFCBK" "Rs.1,299.00 refund credited to A/c XX4521 from FLIPKART. Avl Bal Rs.98,639.50"

# B20 — 'reversal' of a failed debit
sms "ICICI" "Rs.500.00 reversal credited to A/c XX7890. UPI Txn ID: 9876543210. Avl Bal INR 8,950.00"

# B21 — 'credited by' with amount in crore (edge case unit)
sms "HDFCBK" "Rs.0.01 crore credited to A/c XX4521 by MUTUAL FUND REDEMPTION. Bal Rs.2,00,000.00"

# B22 — 'deposit' (noun form, not 'deposited')
sms "BOBSMS" "Deposit of Rs.10,000.00 received in A/c XX8877 on 20-05-26. Avl Bal Rs.14,321.00"

# B23 — 'added to your account'
sms "ICICI" "Rs.2,500.00 added to your account XX7890 by REFERRAL BONUS. Avl Bal INR 11,450.00"

# B24 — 'transfer from' keyword
sms "CENTBK" "Rs.20,000.00 transfer from SAVINGS A/c XX1010 credited to FD. Bal Rs.7,800.00"

# B25 — 'from vpa' keyword
sms "PAYZAP" "INR 750.00 credited from vpa shopkeeper@upi. A/c XX7711. Avl Bal Rs.2,750.00"

# ── C: Declined — should parse as DECLINED ───────────────────────────────────
echo ""
echo "▸ Category C: Declined (expect: DECLINED)"

# C26 — 'declined' with merchant
sms "HDFCBK" "Your transaction of Rs.5,000.00 at MERCHANT STORE using Card XX4521 was declined. Please check balance."

# C27 — 'failed' payment
sms "ICICI" "UPI payment of INR 1,500.00 to vendor@paytm failed. Ref: 11223344556. No amount debited."

# C28 — Declined with account info
sms "KOTAK" "Transaction declined: Rs.800.00 at PETROL PUMP for Card XX4321. Please retry or use another card."

# ── D: Exclusion keyword — should be FILTERED OUT ────────────────────────────
echo ""
echo "▸ Category D: Exclusion keywords (expect: NOT PARSED)"

# D29 — OTP message (exclusion: 'otp')
sms "HDFCBK" "Your OTP for A/c XX4521 transaction is 847291. Valid for 10 minutes. Do not share."

# D30 — Cashback (exclusion: 'cashback')
sms "ICICI" "Congratulations! Rs.100 cashback credited to A/c XX7890 on your recent transaction."

# D31 — Discount offer (exclusion: 'discount')
sms "KOTAK" "Special offer: 20% discount on all transactions this weekend. Use your Kotak card now!"

# D32 — Sale notification (exclusion: 'sale')
sms "HDFCBK" "Big Billion Day sale starts now! Use your HDFC card and get extra benefits. Shop now!"

# D33 — Congratulations (exclusion: 'congratulations')
sms "ICICI" "Congratulations! Your A/c XX7890 has been upgraded to premium banking. No charges applied."

# D34 — Outstanding balance (exclusion: 'outstanding')
sms "HDFCBK" "Your credit card A/c XX4521 has outstanding due of Rs.12,500 by 05-06-26. Please pay."

# D35 — Due date reminder (exclusion: 'due')
sms "KOTAK" "Reminder: Rs.5,200.00 is due for payment on your A/c XX4321 by 10-06-26. Pay now."

# ── E: Non-whitelisted sender — should be FILTERED OUT ───────────────────────
echo ""
echo "▸ Category E: Non-whitelisted senders (expect: NOT PARSED)"

# E36 — Looks valid but sender not in whitelist
sms "AMAZON" "Rs.999.00 debited from A/c XX1234 for Prime Renewal. Avl Bal Rs.5,000.00"

# E37 — Paytm (not in whitelist)
sms "PAYTM" "Rs.250.00 debited from your account XX9876. A/c Bal Rs.1,500.00"

# E38 — Random bank not in whitelist
sms "YESBNK" "Rs.5,000.00 debited from A/c XX5555. Avl Bal Rs.25,000.00"

# ── F: Amount extraction edge cases — should parse ───────────────────────────
echo ""
echo "▸ Category F: Amount edge cases (expect: parsed with correct amounts)"

# F39 — 1 lakh (spelled out)
sms "HDFCBK" "Rs.1 lakh debited from A/c XX4521 to INVESTMENT FUND. Avl Bal Rs.50,000.00"

# F40 — 2.5 crore
sms "ICICI" "INR 2.5 crore credited to A/c XX7890 from PROPERTY SALE. Bal Rs.2,50,50,000.00"

# F41 — Indian lakh format with commas (1,00,000)
sms "KOTAK" "Rs.1,50,000.00 debited from A/c XX4321 via NEFT. Avl Bal Rs.3,00,000.00"

# F42 — Small decimal amount
sms "HDFCBK" "Rs.9.50 debited from A/c XX4521 at CHAI TAPRI. Avl Bal Rs.12,330.00"

# F43 — Amount before INR (suffix format)
sms "SBIUPI" "500 INR debited from A/c XX1122. Merchant: IRCTC. Avl Bal Rs.6,734.56"

# F44 — Amount after keyword with no currency symbol
sms "AIRBNK" "Spent 1500 for online purchase from A/c XX4433. Available Bal Rs.3,000.75"

# F45 — Very small amount (1 rupee)
sms "ICICI" "Rs.1.00 debited from A/c XX7890 as UPI verification charge. Avl Bal INR 8,949.00"

# ── G: Merchant extraction edge cases ────────────────────────────────────────
echo ""
echo "▸ Category G: Merchant extraction edge cases"

# G46 — UPI ID takes priority over keyword-based merchant
sms "HDFCBK" "Rs.300.00 sent to grocery@oksbi at KIRANA STORE from A/c XX4521. Bal Rs.12,030.50"

# G47 — Merchant with ampersand in name
sms "KOTAK" "Rs.2,200.00 debited for purchase at H&M INDIA. Card XX4321. Avl Bal Rs.29,900.00"

# G48 — Multi-word merchant name ending at balance keyword
sms "ICICI" "INR 1,100.00 debited at THE COFFEE HOUSE MUMBAI. A/c XX7890. Avl Bal INR 7,849.00"

# G49 — Credit with 'by' merchant (no UPI ID)
sms "HDFCBK" "Rs.3,000.00 credited by GOOGLE PAY REFUND to A/c XX4521. Avl Bal Rs.15,340.50"

# G50 — 'trf to' keyword merchant
sms "SBIUPI" "Rs.25,000.00 trf to HDFC BANK NEFT from A/c XX1122. Avl Bal Rs.35,000.00"

echo ""
echo "══════════════════════════════════════════════════════════════"
echo "  Done! 50 messages injected."
echo "  Open the TestSMS tab in the Fynans app to see parsed results."
echo ""
echo "  Expected counts:"
echo "    DEBIT    : 15 (A01–A15)"
echo "    CREDIT   : 10 (B16–B25)"
echo "    DECLINED :  3 (C26–C28)"
echo "    FILTERED : 10 (D29–D35 exclusion keywords, E36–E38 non-whitelist)"
echo "    Parseable: 37 (A+B+C+F+G, minus any regex edge case misses)"
echo "══════════════════════════════════════════════════════════════"
echo ""
