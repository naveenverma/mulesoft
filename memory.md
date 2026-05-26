# Memory: MuleSoft GL Integration Project

> **Session**: Initial project scaffolding and implementation
> **Date**: May 26, 2026
> **Model**: deepseek/deepseek-v4-flash

---

## Project Overview

MuleSoft integration that transforms General Ledger (GL) custom object data from Salesforce (CSV format) into payloads compatible with Blackbaud Financial Edge NXT SKY API endpoints.

**Repository**: `mule-gl-salesforce-to-blackbaud`
**Group ID**: `com.mulesoft.integration`
**Version**: `1.0.0-SNAPSHOT`
**Mule Runtime**: 4.4.0 EE

---

## Architecture

### 3-Layer MuleSoft Architecture

```
Experience API (Layer 1)
    ↓ HTTP / API
Process API (Layer 2)
    ↓ Flow-ref
System API (Layer 3)
    ↓ HTTPS
Blackbaud SKY API
```

| Layer | File(s) | Responsibility |
|-------|---------|----------------|
| **Experience API** | `experience-api.xml` | HTTP endpoints, file upload, health check |
| **Process API** | `process-api.xml` | CSV parsing, validation, business rules, DataWeave transform |
| **System API** | `system-api.xml`, `authentication-flow.xml` | SKY API HTTP client, OAuth2 auth, retry logic |
| **Cross-cutting** | `error-handling-flow.xml`, `logging-flow.xml`, `business-rules-flow.xml` | Error handling, structured logging, business rules |

### Integration Flow

```
CSV Input → Parse CSV → Validate Fields → Apply Business Rules
→ DataWeave Transformation → Authenticate with SKY API
→ Submit Request → Capture Response → Log Results → Return Status
```

---

## File Structure

```
/
├── memory.md                        ← This file
├── mulesoft.md                      ← Original PDR (requirements)
├── pom.xml                          ← Maven build
├── mule-artifact.json               ← Mule artifact descriptor
├── mapping-matrix.md                ← Field mapping matrix (client-facing)
├── test-cases.md                    ← Test scenarios documentation
├── deployment-instructions.md       ← Deployment guide
├── .gitignore
│
├── src/main/dw/                     ← DataWeave transformation modules
│   ├── common-functions.dwl         ← Shared utilities (dates, numbers, strings)
│   ├── field-mapping.dwl            ← Dynamic field mapping engine
│   ├── csv-to-journal.dwl           ← CSV → Journal Entry Batch transform
│   └── csv-to-distribution.dwl      ← CSV → Distribution lines transform
│
├── src/main/mule/                   ← Mule XML flow definitions
│   ├── global-config.xml            ← Global config (HTTP, file, objectstore connectors)
│   ├── authentication-flow.xml      ← OAuth2 token flow (acquire, cache, refresh)
│   ├── system-api.xml               ← SKY API client (submit, retry, mock mode)
│   ├── business-rules-flow.xml      ← 7 configurable business rules
│   ├── process-api.xml              ← Processing orchestration pipeline
│   ├── experience-api.xml           ← HTTP API endpoints (4 endpoints)
│   ├── error-handling-flow.xml      ← Error handling (rejections, API failures)
│   └── logging-flow.xml             ← Structured logging (audit, error, integration)
│
├── src/main/resources/              ← Configuration files
│   ├── application.properties       ← Global config defaults
│   ├── business-rules.properties    ← Configurable business rules
│   ├── log4j2.xml                   ← Logging configuration
│   ├── dev/application-template.properties
│   ├── staging/application-template.properties
│   └── production/application-template.properties
│
└── src/test/resources/              ← Test data
    ├── sample-valid.csv             ← 10 valid records
    ├── sample-missing-fields.csv    ← 8 records with nulls
    └── sample-invalid-accounts.csv  ← 5 records with bad accounts
```

---

## Key Implementation Decisions

### Authentication (OAuth2)
- Token endpoint: `https://oauth2.sky.blackbaud.com/token`
- Grant types supported: `client_credentials` (primary), `authorization_code` (with refresh)
- Cached in ObjectStore with 3600s TTL
- Auto-refresh on 401 responses

### Business Rules (All Configurable)
1. **Amount validation**: Reject if Amount ≤ threshold (default: 0)
2. **Default journal**: Assign "DEFAULT_JOURNAL" when missing
3. **Account validation**: Validate format, send invalid to error queue
4. **Date conversion**: MM/dd/yyyy → yyyy-MM-dd
5. **Null handling**: Omit field, convert to empty string, or use default
6. **String trimming**: Trim all string fields
7. **Numeric conversion**: Safe conversion with default fallback

### Mock Mode
- DEV environment uses `sky.api.mock.enabled=true`
- Returns synthetic successful responses without hitting live API
- Logs the payload that would have been sent

### Error Handling
| HTTP Status | Action |
|-------------|--------|
| 429 | Retry with exponential backoff |
| 500/503 | Retry with exponential backoff |
| 401 | Refresh token, then retry |
| 400 | Log and fail (no retry) |
| Timeout | Retry with backoff |

### DataWeave Design
- No hardcoded field names or IDs
- Null-safe mappings throughout
- Dynamic field detection from CSV headers
- Type inference from sample values
- All unclear SKY API fields marked `REQUIRES CLIENT CONFIRMATION`

---

## Open Items (Requiring Client Input)

### 1. SKY API Payload Schemas
The actual field names for Journal Entry Batch, Journal Entry, and Distribution entities **cannot be determined** without access to the live SKY API interactive documentation (requires Blackbaud developer account login).

**Affected files**: `src/main/dw/csv-to-journal.dwl`, `src/main/dw/csv-to-distribution.dwl`
**All unresolved mappings are marked** with `REQUIRES CLIENT CONFIRMATION` comments.

### 2. Field Mapping
14 example fields are mapped with HIGH/MEDIUM confidence. Any additional fields from the actual CSV (~50+ expected) will be dynamically detected but flagged with:
> "REQUIRES CLIENT CONFIRMATION"

### 3. Endpoint Paths
Confirm the exact SKY API endpoint path:
- `POST /fe/general-ledger/journalentrybatches` (original, possibly deprecated)
- Or a newer process-based endpoint

### 4. Business Rules
Current rules are temporary defaults. Client should confirm/adjust:
- Amount rejection threshold
- Default journal value
- Account number validation rules
- Any additional business rules

### 5. Non-functional Requirements
- Scheduling (scheduled polling vs on-demand)
- Notifications on failure
- Log retention period

### 6. Environment & Credentials
Need actual values for:
- `CLIENT_ID`, `CLIENT_SECRET`, `SUBSCRIPTION_KEY`, `REFRESH_TOKEN`
- Environment URLs (dev/staging/production sandboxes)

---

## Testing

### Test CSV Files
| File | Records | Purpose |
|------|---------|---------|
| `sample-valid.csv` | 10 | Positive scenario |
| `sample-missing-fields.csv` | 8 | Missing/null field handling |
| `sample-invalid-accounts.csv` | 5 | Account validation |

### Test Scenarios (see `test-cases.md` for full details)
1. Positive: all 10 records processed successfully
2. Missing fields: 3 processed, 5 rejected
3. Invalid accounts: 5 sent to error queue
4. API failures: retry logic for 429, 500, 401, timeout
5. Token expiration: cache → refresh flow

---

## Session Resume Points

### Next development priorities:
1. **Obtain SKY API credentials** and update `src/main/resources/*/application.properties`
2. **Access live SKY API docs** at [developer.blackbaud.com/skyapi/products/fenxt/general-ledger/entities](https://developer.blackbaud.com/skyapi/products/fenxt/general-ledger/entities) to confirm payload schemas
3. **Update DataWeave mappings** once actual field names are confirmed
4. **Deploy to DEV** using `mvn mule:run -Denvironment=DEV`
5. **Write MUnit tests** (test framework configured in pom.xml)

### Commands:
```bash
# Build
mvn clean package -DskipTests

# Run locally (DEV with mock mode)
mvn mule:run -Denvironment=DEV

# Run locally (with live API)
mvn mule:run -Denvironment=STAGING
```

### API Endpoints (when running):
```bash
POST /api/v1/gl/process         # Process CSV payload
POST /api/v1/gl/process/file    # Process CSV from input directory
GET  /api/v1/gl/status/{id}     # Check status (placeholder)
GET  /api/v1/gl/health          # Health check
```
