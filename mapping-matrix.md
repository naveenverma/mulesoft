# Field Mapping Matrix

> **Generated**: Planning phase
> **Status**: Preliminary — requires client confirmation
> **Source**: Salesforce GL Custom Object (CSV)
> **Target**: Blackbaud Financial Edge NXT (SKY API)

## Mapping Matrix

| # | Source Field | Type | Suggested Target Entity | Target Field | Confidence | Notes |
|---|---|---|---|---|---|---|
| 1 | `Amount` | Number | Journal Entry Distribution | `amount` | HIGH | Core GL field — maps to distribution amount |
| 2 | `CreditAccountNumber` | String | Journal Entry Distribution | `account_number` | HIGH | Credit leg of the transaction |
| 3 | `DebitAccountNumber` | String | Journal Entry Distribution | `account_number` | HIGH | Debit leg of the transaction |
| 4 | `Journal` | String | Journal Entry Batch | `description` | MEDIUM | May map to batch description or entry reference |
| 5 | `ProjectId` | String | Journal Entry | `project_id` | MEDIUM | Common GL tracking field |
| 6 | `Payment` | Number | Journal Entry Distribution | `payment_amount` | MEDIUM | Payment portion of the transaction |
| 7 | `TenderType` | String | Journal Entry Distribution | `tender_type` | MEDIUM | CHECK, WIRE, CREDIT_CARD, CASH, ACH |
| 8 | `AccountCode` | String | Journal Entry Distribution | `account_code` | MEDIUM | May be alternate account identifier |
| 9 | `Description` | String | Journal Entry | `description` | HIGH | Standard transaction description |
| 10 | `TransactionDate` | Date | Journal Entry | `transaction_date` | HIGH | Core transaction date field |
| 11 | `ReferenceNumber` | String | Journal Entry | `reference_number` | HIGH | External reference identifier |
| 12 | `Fund` | String | Journal Entry | `fund` | MEDIUM | Nonprofit fund accounting field |
| 13 | `Program` | String | Journal Entry | `program` | MEDIUM | Program tracking (FASB requirement) |
| 14 | `Campaign` | String | Journal Entry | `campaign` | MEDIUM | Campaign tracking |

## Confirmation Status

| Status | Count |
|--------|-------|
| **HIGH** confidence (mapping likely correct) | 5 |
| **MEDIUM** confidence (plausible, needs confirmation) | 9 |
| **LOW** confidence (requires client input) | 0 |
| **REQUIRES CLIENT CONFIRMATION** | 0 |

## Unknown Fields

Any fields in the actual CSV that are not listed above will be flagged as:

> **REQUIRES CLIENT CONFIRMATION**

when attempting to map them, with a `LOW` confidence rating. The `field-mapping.dwl` module handles this dynamically.

## Critical API Schema Dependencies

The following cannot be determined without access to the live SKY API documentation (requires Blackbaud developer account):

1. **Journal Entry Batch entity** — exact field names and required/optional constraints
2. **Journal Entry entity** — field schema and nested structure
3. **Distribution entity** — field schema for credit/debit line items
4. **Endpoint paths** — confirmation of `/journalentrybatches` vs process-based endpoint
5. **Batch creation vs process** — whether direct POST or async process submission is required

All DataWeave transformation modules mark these unresolved fields with `REQUIRES CLIENT CONFIRMATION` comments.
