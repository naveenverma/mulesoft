# Deployment Instructions

## MuleSoft GL Integration — Salesforce CSV to Blackbaud FENXT

---

## Prerequisites

1. **Mule Runtime** 4.4.0+ (Enterprise Edition)
2. **Java** 8 or 11
3. **Maven** 3.6+
4. **Anypoint Studio** 7.x (for development/editing)
5. **Blackbaud SKY API Credentials**:
   - Client ID
   - Client Secret
   - Subscription Key
   - Refresh Token (if using authorization_code grant)

---

## Local Deployment

### 1. Configure Environment Properties

Copy the environment template and fill in credentials:

```bash
# For DEV environment
cp src/main/resources/dev/application-template.properties src/main/resources/dev/application.properties

# Edit with your credentials
# sky.api.client.id=<your_client_id>
# sky.api.client.secret=<your_client_secret>
# sky.api.subscription.key=<your_subscription_key>
# sky.api.refresh.token=<your_refresh_token>
```

### 2. Build the Application

```bash
mvn clean package -DskipTests
```

### 3. Run Locally

```bash
mule run -M-Denvironment=DEV
```

Or deploy to embedded Mule:

```bash
mvn mule:run -Denvironment=DEV
```

---

## CloudHub Deployment

### 1. Build the JAR

```bash
mvn clean package -Dmule.env=DEV
```

### 2. Deploy to CloudHub

Using Anypoint Platform CLI:

```bash
anypoint-cli cloudhub application deploy \
  --artifact target/mule-gl-salesforce-to-blackbaud-1.0.0-SNAPSHOT-mule-application.jar \
  --environment DEV \
  --properties src/main/resources/dev/application.properties
```

Or via **Anypoint Studio** → Right-click project → Run As → Mule Application → Deploy to CloudHub.

### 3. Set Environment-Specific Properties

In CloudHub, set the following properties in the deployment configuration:

| Property | DEV | STAGING | PRODUCTION |
|----------|-----|---------|------------|
| `environment` | DEV | STAGING | PRODUCTION |
| `http.port` | 8081 | 8082 | 8080 |
| `batch.size` | 100 | 500 | 250 |
| `sky.api.mock.enabled` | true | false | false |
| `sky.api.retry.count` | 3 | 3 | 5 |
| `sky.api.timeout.ms` | 30000 | 30000 | 60000 |

---

## API Endpoints

After deployment, the following endpoints are available:

| Method | Path | Description |
|--------|------|-------------|
| POST | `/api/v1/gl/process` | Process CSV payload (send CSV in body) |
| POST | `/api/v1/gl/process/file` | Process CSV from configured input directory |
| GET | `/api/v1/gl/status/{id}` | Check processing status (placeholder) |
| GET | `/api/v1/gl/health` | Health check |

### Example: Process CSV

```bash
curl -X POST http://localhost:8081/api/v1/gl/process \
  -H "Content-Type: text/csv" \
  -d 'Amount,CreditAccountNumber,DebitAccountNumber,Description,TransactionDate,Journal
1000.00,40001,20001,"Payment Entry",01/15/2024,JNL-001'
```

### Example: Upload CSV File

```bash
curl -X POST http://localhost:8081/api/v1/gl/process \
  -F "file=@sample-valid.csv"
```

---

## Directory Structure (Runtime)

The application expects the following directories at runtime (configurable in properties):

```
./input/          → Drop CSV files here for file-based processing
./archive/        → Processed files are moved here
./error/          → Rejected records and error logs
./status/         → Processing status outputs
./logs/           → Application logs
```

---

## Configuration Reference

### Application Properties (`application.properties`)

| Property | Default | Description |
|----------|---------|-------------|
| `http.port` | 8081 | HTTP listener port |
| `http.basePath` | /api/v1/gl | API base path |
| `batch.size` | 100 | Records per batch |
| `processing.mode` | BATCH | BATCH or REALTIME |
| `retry.count` | 3 | API retry attempts |
| `timeout.ms` | 30000 | API timeout in milliseconds |

### SKY API Properties (`dev/application.properties`)

| Property | Placeholder | Description |
|----------|-------------|-------------|
| `sky.api.client.id` | `${CLIENT_ID}` | OAuth client ID |
| `sky.api.client.secret` | `${CLIENT_SECRET}` | OAuth client secret |
| `sky.api.subscription.key` | `${SUBSCRIPTION_KEY}` | API subscription key |
| `sky.api.refresh.token` | `${REFRESH_TOKEN}` | OAuth refresh token |
| `sky.api.auth.url` | `https://oauth2.sky.blackbaud.com/token` | Token endpoint |
| `sky.api.base.url` | `https://api.sky.blackbaud.com/fe/general-ledger` | API base URL |
| `sky.api.mock.enabled` | `true` | Enable mock mode (DEV only) |

### Business Rules (`business-rules.properties`)

| Property | Default | Description |
|----------|---------|-------------|
| `rule.amount.rejection.threshold` | 0 | Reject records with Amount ≤ this value |
| `rule.journal.default.value` | DEFAULT_JOURNAL | Default journal for missing values |
| `rule.account.validation.enabled` | true | Enable account validation |
| `rule.null.handling.action` | OMIT_FIELD | OMIT_FIELD, EMPTY_STRING, or DEFAULT_VALUE |
| `rule.date.input.format` | MM/dd/yyyy | Input date format |
| `rule.date.output.format` | yyyy-MM-dd | Output date format |

---

## Monitoring

### Health Check

```bash
curl http://localhost:8081/api/v1/gl/health
```

Response:
```json
{
  "status": "UP",
  "service": "MuleSoft GL Integration",
  "version": "1.0.0",
  "environment": "DEV",
  "mockMode": "true",
  "timestamp": "2024-01-15T10:30:00Z"
}
```

### Logs

Logs are written to the `./logs/` directory:

| File | Content |
|------|---------|
| `gl-integration.log` | All integration events |
| `gl-integration-error.log` | Error-level events only |
| `gl-integration-audit.log` | Processing audit trail |

Log format (structured JSON):
```json
{
  "timestamp": "2024-01-15T10:30:00.000+0000",
  "transactionId": "uuid",
  "level": "INFO",
  "message": "..."
}
```
