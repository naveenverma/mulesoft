Project Design Requirement (PDR)

Project:
MuleSoft Integration – Salesforce GL CSV Object → Blackbaud Financial Edge NXT (SKY API)

Objective:
Develop a MuleSoft integration that transforms General Ledger (GL) custom object data originating from Salesforce (provided as CSV flat file format) into payloads compatible with Blackbaud Financial Edge NXT SKY API endpoints.

Do NOT assume field names, business rules, or endpoint structures. Use only explicitly provided data and official API schemas.

Documentation Reference:
https://developer.blackbaud.com/skyapi/products/fenxt

Input Source:
Source data comes from a CSV flat file exported from Salesforce containing GL custom object records.

Input characteristics:

* Approximately 50+ fields
* Financial/accounting related data
* Example fields include:
  Amount
  CreditAccountNumber
  DebitAccountNumber
  Journal
  ProjectId
  Payment
  TenderType
  AccountCode
  Description
  TransactionDate
  ReferenceNumber
  Fund
  Program
  Campaign
  Custom fields

Input Processing Requirements:

1. Read CSV records from source file
2. Validate mandatory fields
3. Handle null values
4. Trim spaces
5. Normalize date formats
6. Convert amount fields to numeric
7. Support batch processing of multiple records
8. Skip invalid records while logging errors

MuleSoft Architecture:

Layer 1:
Experience API

Responsibilities:

* Accept source requests
* Trigger processing
* Return processing response

Layer 2:
Process API

Responsibilities:

* Business rules
* Data transformation
* Validation
* Orchestration

Layer 3:
System API

Responsibilities:

* Blackbaud SKY API communication
* Authentication handling
* Retry logic

Integration Flow:

CSV Input
↓

Read CSV

↓

Validate fields

↓

Apply business rules

↓

DataWeave transformation

↓

Generate Financial Edge payload

↓

Authenticate with SKY API

↓

Submit request

↓

Capture response

↓

Log results

↓

Return status

Authentication Requirements:

Use SKY API authentication:

Required:

* Client ID
* Client Secret
* Subscription Key
* OAuth token
* Refresh token handling

Token management requirements:

* Automatically refresh expired tokens
* Reuse active tokens
* Handle authentication failures

DataWeave Requirements:

Create reusable DataWeave mapping modules.

Requirements:

* No hardcoded field names
* No hardcoded IDs
* Null-safe mappings
* Conditional mapping support
* Dynamic field transformations
* Default values where required

Example transformation pattern:

Input:

{
"Amount":"1000",
"CreditAccountNumber":"40001",
"DebitAccountNumber":"20001",
"Description":"Payment Entry"
}

Output:

{
"amount":1000,
"description":"Payment Entry",
"creditAccount":{
"account_number":"40001"
},
"debitAccount":{
"account_number":"20001"
}
}

Business Rules Layer:

Rules must be configurable.

Examples:

Rule 1:
If Amount <=0
Reject record

Rule 2:
If Journal missing
Assign default journal

Rule 3:
If Account Number invalid
Send to error queue

Rule 4:
Date conversion:
MM/DD/YYYY
→
YYYY-MM-DD

Rule 5:
Null values:
Convert to empty string or omit field

Error Handling:

Must include:

* Try/catch strategy
* API timeout handling
* Authentication failures
* Validation failures
* Invalid mapping failures
* Retry mechanism

Retry rules:

HTTP 429:
Retry

HTTP 500:
Retry

HTTP 401:
Refresh token then retry

Logging Requirements:

Create structured logs:

Fields:

TransactionId
SourceRecordId
Timestamp
Status
RequestPayload
ResponsePayload
ErrorMessage

Testing Requirements:

Create:

1. Sample CSV dataset testing
2. Positive scenario testing
3. Missing field testing
4. Invalid account testing
5. API failure testing
6. Token expiration testing

Deliverables:

1. MuleSoft project
2. DataWeave mapping scripts
3. API configuration
4. Authentication flow
5. Error handling flow
6. Logging implementation
7. Sample transformed output
8. Deployment instructions

Critical Instructions For AI:

DO NOT invent Blackbaud payload fields.
DO NOT hallucinate endpoint schemas.
DO NOT create assumptions for business rules.
DO NOT hardcode values.
ONLY use official SKY API request structures.
If required information is missing, explicitly return:

"Additional mapping information required"

instead of generating fake implementation.

