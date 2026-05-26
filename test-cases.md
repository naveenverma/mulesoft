# Test Cases

## Test Data Files

| File | Description |
|------|-------------|
| `src/test/resources/sample-valid.csv` | 10 valid records — positive scenario |
| `src/test/resources/sample-missing-fields.csv` | 8 records with missing/null fields |
| `src/test/resources/sample-invalid-accounts.csv` | 5 records with invalid account numbers |

---

## Test Scenario 1: Positive Scenario

**File**: `sample-valid.csv`

**Expected Results**:
| Record | Amount | Credit Account | Debit Account | Expected Status |
|--------|--------|----------------|---------------|-----------------|
| 1 | 1000.00 | 40001 | 20001 | ✅ Processed |
| 2 | 2500.50 | 40002 | 20002 | ✅ Processed |
| 3 | 750.00 | 40003 | 20003 | ✅ Processed |
| 4 | 3200.00 | 40004 | 20004 | ✅ Processed |
| 5 | 150.75 | 40005 | 20005 | ✅ Processed |
| 6 | 5000.00 | 40006 | 20006 | ✅ Processed |
| 7 | 1250.00 | 40007 | 20007 | ✅ Processed |
| 8 | 890.00 | 40008 | 20008 | ✅ Processed |
| 9 | 3400.00 | 40009 | 20009 | ✅ Processed |
| 10 | 675.50 | 40010 | 20010 | ✅ Processed |

**Expected Summary**: 10 processed, 0 rejected, 0 errors

---

## Test Scenario 2: Missing Field Testing

**File**: `sample-missing-fields.csv`

**Expected Results**:
| Record | Issue | Rule Triggered | Expected Status |
|--------|-------|---------------|-----------------|
| 1 | Amount = -100.00 | Rule 1 (Amount ≤ 0) | ❌ Rejected |
| 2 | Amount = 0.00 | Rule 1 (Amount ≤ 0) | ❌ Rejected |
| 3 | Missing CreditAcct + Missing Journal | Validation + Rule 2 | ❌ Rejected (validation), Journal → DEFAULT |
| 4 | Missing DebitAccount | Validation | ❌ Rejected |
| 5 | Missing TenderType + Payment | Rule 5 (Null handling) | ✅ Processed (null omitted) |
| 6 | Missing Description + AccountCode + Date | Validation | ❌ Rejected |
| 7 | Missing TenderType (with Payment) | Rule 5 (Null handling) | ✅ Processed |
| 8 | Missing Amount | Validation | ❌ Rejected |

**Expected Summary**: 3 processed, 5 rejected

---

## Test Scenario 3: Invalid Account Testing

**File**: `sample-invalid-accounts.csv`

**Expected Results**:
| Record | Issue | Rule Triggered | Expected Status |
|--------|-------|---------------|-----------------|
| 1 | CreditAccount = `INVALID-01` | Rule 3 (Invalid account) | ❌ Error Queue |
| 2 | DebitAccount = `BAD-ACC-02` | Rule 3 (Invalid account) | ❌ Error Queue |
| 3 | CreditAccount contains `!@#` | Rule 3 (Invalid characters) | ❌ Error Queue |
| 4 | DebitAccount = `99999` (non-existent) | Rule 3 (Invalid account) | ❌ Error Queue |
| 5 | CreditAccount = `00000` (zero) | Rule 3 (Invalid account) | ❌ Error Queue |

**Expected Summary**: 0 processed, 0 rejected, 5 error queue

---

## Test Scenario 4: API Failure Testing

| Scenario | Simulated Error | Expected Behavior |
|----------|----------------|-------------------|
| HTTP 429 | Rate limited | Retry with backoff (up to `retry.count`) |
| HTTP 500 | Server error | Retry with backoff (up to `retry.count`) |
| HTTP 401 | Unauthorized | Refresh token then retry |
| HTTP 400 | Bad request | Log and fail (no retry) |
| Timeout | Connection timeout | Retry with backoff |
| Network error | Connection refused | Retry with backoff |

---

## Test Scenario 5: Token Expiration Testing

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Initial request | New token acquired and cached |
| 2 | Subsequent request within TTL | Cached token reused |
| 3 | Force token expiry (wait or mock) | Token refreshed automatically |
| 4 | Refresh token failure | Error logged, request fails gracefully |

---

## Configuration Overrides for Testing

To test specific scenarios without live API access, set in properties:

```properties
# Enable mock mode (no live API calls)
sky.api.mock.enabled=true

# Override business rules
rule.amount.rejection.threshold=0
rule.journal.default.value=TEST_JOURNAL
rule.null.handling.action=OMIT_FIELD
```
