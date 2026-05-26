%dw 2.0

// =============================================================================
// CSV to Distribution Transformation
// =============================================================================
// Handles the split distribution mapping from CSV records to individual
// GL distribution line items (credit and debit leg).
//
// NOTE: Actual SKY API distribution schema REQUIRES CLIENT CONFIRMATION.
// =============================================================================

import * from common-functions

// --- Distribution Entity Mapping ---
// REQUIRES CLIENT CONFIRMATION: The distribution entity structure below
// is based on general accounting principles and documented patterns.
// Verify against:
// https://developer.blackbaud.com/skyapi/products/fenxt/general-ledger/entities

// Create a credit distribution from a CSV record
fun toCreditDistribution(record: Object): Object = {
    // REQUIRES CLIENT CONFIRMATION: Distribution field names
    "account_number": trimSafe(record.CreditAccountNumber) default null,
    "amount": parseNumberSafe(record.Amount as String, 0),
    "type": "Credit",
    "description": trimSafe(record.Description),
    "reference": trimSafe(record.ReferenceNumber),
    "tender_type": trimSafe(record.TenderType) default null,
    "payment_amount": parseNumberSafe(record.Payment as String, 0) default null
} when (!isEmpty(record.CreditAccountNumber)) otherwise null

// Create a debit distribution from a CSV record
fun toDebitDistribution(record: Object): Object = {
    // REQUIRES CLIENT CONFIRMATION: Distribution field names
    "account_number": trimSafe(record.DebitAccountNumber) default null,
    "amount": parseNumberSafe(record.Amount as String, 0),
    "type": "Debit",
    "description": trimSafe(record.Description),
    "reference": trimSafe(record.ReferenceNumber),
    "tender_type": trimSafe(record.TenderType) default null,
    "payment_amount": parseNumberSafe(record.Payment as String, 0) default null
} when (!isEmpty(record.DebitAccountNumber)) otherwise null

// Create both distributions from a single CSV record
fun toSplitDistributions(record: Object): Array = (
    flatten([
        toCreditDistribution(record),
        toDebitDistribution(record)
    ])
) filter ((dist) -> dist != null)

// --- Distribution Array Processing ---

// Process an array of CSV records into an array of distributions
fun toDistributionArray(records: Array): Array =
    flatten(records map ((record) -> toSplitDistributions(record)))

// Validate that total credits equal total debits
fun validateBalancedDistributions(distributions: Array): Boolean = (
    (distributions filter ((d) -> d.type == "Credit")) map ((d) -> d.amount) reduce ((val, acc) -> val + acc)
    ==
    (distributions filter ((d) -> d.type == "Debit")) map ((d) -> d.amount) reduce ((val, acc) -> val + acc)
)

// --- Account Validation ---

// Check if an account number appears valid (non-empty, numeric test)
fun isValidAccountNumber(accountNumber: String): Boolean =
    !isEmpty(accountNumber) and (accountNumber matches /^[A-Za-z0-9\-_]+$/)

// Validate all accounts in a distribution array
fun validateDistributions(distributions: Array): Array =
    distributions map ((dist) ->
        dist ++ {
            "validation_errors": (
                if (!isValidAccountNumber(dist.account_number default ""))
                    ["Invalid account number: $(dist.account_number)"]
                else []
            )
        }
    )
