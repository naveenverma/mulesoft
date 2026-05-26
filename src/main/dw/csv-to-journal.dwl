%dw 2.0

// =============================================================================
// CSV to Journal Entry Batch Transformation
// =============================================================================
// Transforms parsed CSV records into a Blackbaud Financial Edge NXT
// journal entry batch payload.
//
// NOTE: Actual SKY API field names REQUIRES CLIENT CONFIRMATION.
// The output structure below uses documented patterns from the
// Microsoft Power Automate connector schema and general REST patterns.
// =============================================================================

import * from common-functions
import * from field-mapping

// --- Output: Journal Entry Batch Payload ---
// This structure is a best-effort mapping based on documented SKY API patterns.
// Fields marked with REQUIRES CLIENT CONFIRMATION need verification.

fun transformToJournalEntryBatch(
    records: Array,
    batchConfig: Object = {
        description: "GL Batch Import",
        postDate: now() as String {format: "yyyy-MM-dd"},
        sourceSystemName: "Salesforce",
        journalEntryBatchType: "Standard"
    }
): Object = {
    description: batchConfig.description,
    post_date: batchConfig.postDate,
    source_system: batchConfig.sourceSystemName,
    journal_entry_batch_type: batchConfig.journalEntryBatchType,

    // REQUIRES CLIENT CONFIRMATION: confirm the actual entity name and path
    journal_entries: records map ((record) -> transformToJournalEntry(record))
}

// Transform a single CSV record into a journal entry
fun transformToJournalEntry(record: Object): Object = {
    // REQUIRES CLIENT CONFIRMATION: The field names below are guessed
    // based on general accounting system patterns.
    // Verify against actual SKY API schema at:
    // https://developer.blackbaud.com/skyapi/products/fenxt/general-ledger/entities

    "journal_entry_id": null, // System-generated on creation
    "description": trimSafe(record.Description),

    // Date fields
    "transaction_date": convertDateFormat(record.TransactionDate),

    // Reference
    "reference_number": trimSafe(record.ReferenceNumber),

    // Amount breakdown
    // REQUIRES CLIENT CONFIRMATION: Confirm field names for debit/credit amounts
    "total_debit": parseNumberSafe(record.Amount as String, 0),
    "total_credit": parseNumberSafe(record.Amount as String, 0),

    // Fund/Program/Campaign - REQUIRES CLIENT CONFIRMATION
    "fund": trimSafe(record.Fund),
    "program": trimSafe(record.Program),
    "campaign": trimSafe(record.Campaign),

    // Source tracking
    "project_id": trimSafe(record.ProjectId),
    "source_record_id": trimSafe(record.ReferenceNumber),

    // Distribution lines
    "distributions": transformToDistributions(record)
}

// Split into credit and debit distributions
fun transformToDistributions(record: Object): Array = [
    // Credit distribution
    // REQUIRES CLIENT CONFIRMATION: Confirm distribution schema
    {
        "account_number": trimSafe(record.CreditAccountNumber),
        "amount": parseNumberSafe(record.Amount as String, 0),
        "type": "CREDIT",
        "description": trimSafe(record.Description),
        "tender_type": trimSafe(record.TenderType),
        "payment": parseNumberSafe(record.Payment as String, 0)
    } when (!isEmpty(record.CreditAccountNumber)) otherwise null,

    // Debit distribution
    {
        "account_number": trimSafe(record.DebitAccountNumber),
        "amount": parseNumberSafe(record.Amount as String, 0),
        "type": "DEBIT",
        "description": trimSafe(record.Description),
        "tender_type": trimSafe(record.TenderType),
        "payment": parseNumberSafe(record.Payment as String, 0)
    } when (!isEmpty(record.DebitAccountNumber)) otherwise null
] filter (value -> value != null)

// --- Helper: Generate a batch summary ---
fun generateBatchSummary(records: Array): Object = {
    totalRecords: sizeOf(records),
    totalAmount: records map ((r) -> parseNumberSafe(r.Amount as String, 0)) reduce ((val, acc) -> val + acc),
    processedAt: now() as String {format: "yyyy-MM-dd'T'HH:mm:ssZ"}
}
