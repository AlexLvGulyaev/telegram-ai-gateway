# SOT Analysis Report — Telegram AI Gateway

**Date:** 2026-07-10
**Analyst:** Claude (AI Agent)
**Purpose:** Compare factual SOT (Source of Truth) from code/configs with documentation

---

## Executive Summary

**Status:** ⚠️ PARTIAL DISCREPANCIES FOUND

**Critical Issues:** 3
**Major Issues:** 5
**Minor Issues:** 4

**Overall:** Documentation is mostly accurate but has important gaps and some inconsistencies with actual implementation.

---

## 1. Workflow Analysis

### 1.1. Node Count

**Factual SOT (from workflow JSON):**
- Total nodes in main workflow: **39**
- Execute Workflow (logging): **11**
- Code nodes: **9**
- If nodes: **7**
- Telegram nodes: **6**
- HTTP Request nodes: **3**
- Set nodes: **2**
- Telegram Trigger: **1**

**Documentation (workflow_overview.md):**
- Main nodes described: **26**
- Error handling nodes described: **13**
- Total described: **39**

**Discrepancy:** ✅ **MATCH** (39 nodes actual vs 39 described)

### 1.2. Node Types Distribution

**Factual SOT:**
```
Execute Workflow: 11 nodes (logging)
Code: 9 nodes (logic)
If: 7 nodes (routing)
Telegram: 6 nodes (send messages)
HTTP Request: 3 nodes (external APIs)
Set: 2 nodes (data preparation)
Telegram Trigger: 1 node (webhook)
```

**Documentation:** Does not provide node type distribution

### 1.3. If Nodes

**Factual SOT (7 If nodes):**
1. **Check URL** — validates URL format
2. **Check Text** — validates extracted text
3. **Content Source Detection** — checks CONTENT_SOURCE config
4. **Provider Entry Point** — checks AI_PROVIDER config
5. **Check Token** — validates GigaChat token
6. **Check Response** — validates GigaChat response
7. **Check Load Error** — checks for HTTP errors

**Documentation (workflow_overview.md):**
- ✅ Check URL — described
- ✅ Check Text — described
- ❌ **Content Source Detection — NOT DOCUMENTED**
- ❌ **Provider Entry Point — NOT DOCUMENTED**
- ❌ **Check Token — NOT DOCUMENTED** (mentioned in diagram but not in node descriptions)
- ✅ Check Response — described
- ✅ Check Load Error — described

**Discrepancy:** ⚠️ **3 If nodes missing from documentation**

### 1.4. Logging Architecture

**Factual SOT (11 logging points):**
```
1. Log REQUEST_RECEIVED
2. Log WORKFLOW_FINISHED
3. Log WORKFLOW_FAILED_INVALID_URL
4. Log PAGE_LOAD_FAILED
5. Log ARTICLE_EXTRACT_FAILED
6. Log TOKEN_FAILED
7. Log LLM_FAILED
8. Log PAGE_LOADED
9. Log TEXT_EXTRACTED
10. Log TOKEN_RECEIVED
11. Log LLM_COMPLETED
```

**Documentation (workflow_overview.md):**
- Describes logging concept
- Lists log levels (INFO, WARNING, ERROR)
- Lists general event categories
- ❌ **Does not document all 11 specific logging points**

**Documentation (logging-integration-guide.md):**
- ✅ Documents logging architecture
- ✅ Documents Log Writer workflow
- ⚠️ Documents only REQUEST_RECEIVED, URL_VALIDATED, PAGE_LOADED as examples
- ❌ **Does not provide complete list of 11 logging points**

**Discrepancy:** ⚠️ **Logging points not fully documented**

---

## 2. Credentials Analysis

### 2.1. Credentials in Main Workflow

**Factual SOT (from workflow JSON):**
```json
{
  "telegramApi": {
    "id": "5QKYRnp7dw5Tzw8I",
    "name": "telegram-ai-gateway-bot"
  }
}
{
  "httpHeaderAuth": {
    "id": "eoio7n1SJbn5g6wE",
    "name": "gigachat-basic-auth"
  }
}
```

**Documentation (credentials-setup.md):**
- ✅ telegram-ai-gateway-bot — documented
- ✅ gigachat-basic-auth — documented
- ✅ Telegram AI Gateway PostgreSQL — documented

**Discrepancy:** ✅ **MATCH** (credentials match documentation)

### 2.2. Credentials in Log Writer Workflow

**Factual SOT (from Log Writer JSON):**
```json
{
  "postgres": {
    "id": "XYEpHwKQnjoeX2O8",
    "name": "Telegram AI Gateway PostgreSQL"
  }
}
```

**Documentation:** ✅ Documented in credentials-setup.md

---

## 3. Docker Configuration

### 3.1. n8n Version

**Factual SOT (docker-compose.yml):**
```yaml
image: docker.n8n.io/n8nio/n8n:2.29.8
```

**Documentation:**
- deployment_guide.md: ✅ **n8n 2.29.8**
- setup.md: ✅ **n8n 2.29.8**
- PROJECT_STATE.md: ✅ **n8n 2.29.8**
- IMPLEMENTATION_PLAN.md: ✅ **n8n 2.29.8**

**Discrepancy:** ✅ **MATCH**

### 3.2. Docker Compose Version

**Factual SOT (docker-compose.yml):**
```yaml
version: '3.8'
```

**Documentation:** Not explicitly documented

**Discrepancy:** ⚠️ Minor gap

### 3.3. PostgreSQL Version

**Factual SOT (docker-compose.yml):**
```yaml
image: postgres:15-alpine
```

**Documentation (architecture.md):**
- ✅ **PostgreSQL 15**

**Discrepancy:** ✅ **MATCH**

### 3.4. Containers

**Factual SOT (docker-compose.yml):**
```yaml
services:
  postgres:
    image: postgres:15-alpine
    container_name: telegram-ai-gateway-postgres
  n8n:
    image: docker.n8n.io/n8nio/n8n:2.29.8
    container_name: telegram-ai-gateway-n8n
```

**Documentation:** ✅ Documented in architecture.md and deployment_guide.md

**Discrepancy:** ✅ **MATCH**

### 3.5. Docker Compose Test

**Factual SOT (docker-compose.test.yml):**
- Different container names (test-postgres, test-n8n)
- Different ports (5680 instead of 5678)
- Different volumes (postgres_test_data, n8n_test_data)
- Mounts workflows and migrations as read-only
- Different network name (telegram-ai-gateway-test)

**Documentation:** Not documented

**Discrepancy:** ⚠️ **Test configuration not documented**

---

## 4. Database Migrations

### 4.1. Migration Files

**Factual SOT:**
```
migrations/
  001_create_workflow_logs.sql
  002_alter_workflow_logs_created_at.sql
```

**Documentation:** ✅ Documented in logging-integration-guide.md

### 4.2. Table Structure

**Factual SOT (001_create_workflow_logs.sql):**
```sql
CREATE TABLE workflow_logs (
    id SERIAL PRIMARY KEY,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    request_id UUID NOT NULL,
    workflow_name VARCHAR(255) NOT NULL,
    workflow_version VARCHAR(50),
    stage VARCHAR(100) NOT NULL,
    event_type VARCHAR(100),
    level VARCHAR(20) NOT NULL DEFAULT 'INFO',
    status VARCHAR(50) NOT NULL DEFAULT 'IN_PROGRESS',
    chat_id VARCHAR(100),
    user_id VARCHAR(100),
    input_url TEXT,
    duration_ms INTEGER,
    message TEXT,
    error_code VARCHAR(50),
    error_message TEXT,
    details JSONB DEFAULT '{}'::jsonb
);
```

**Documentation:** ✅ Matches logging-integration-guide.md

### 4.3. Migration 002

**Factual SOT (002_alter_workflow_logs_created_at.sql):**
```sql
ALTER TABLE workflow_logs
ALTER COLUMN created_at DROP DEFAULT;

ALTER TABLE workflow_logs
ALTER COLUMN created_at SET NOT NULL;
```

**Purpose:** Remove DEFAULT to allow passing created_at from n8n

**Documentation:** ✅ Documented in logging-integration-guide.md

**Discrepancy:** ✅ **MATCH**

---

## 5. Environment Variables

### 5.1. .env.example Structure

**Factual SOT (.env.example):**
```bash
# PostgreSQL
POSTGRES_USER=n8n
POSTGRES_PASSWORD=your_secure_postgres_password_here
POSTGRES_DB=n8n

# n8n
N8N_PORT=5678
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=your_secure_n8n_password_here
WEBHOOK_URL=
GENERIC_TIMEZONE=UTC
N8N_LOG_LEVEL=info
EXECUTIONS_MODE=regular

# Telegram
TELEGRAM_BOT_TOKEN=your_telegram_bot_token_here

# GigaChat
GIGACHAT_AUTH_KEY=your_base64_encoded_credentials_here
GIGACHAT_SCOPE=GIGACHAT_API_PERS

# Workflow Configuration (NOT USED - hardcoded in workflow)
# GIGACHAT_MODEL=GigaChat-2-Max
# GIGACHAT_TEMPERATURE=0.1
# MAX_TEXT_LENGTH=12000
# MAX_PROMPT_LENGTH=5000
# MAX_MESSAGE_LENGTH=4096
```

**Documentation:** ✅ Matched in deployment_guide.md and setup.md

### 5.2. Hardcoded Configuration

**Factual SOT (Configuration node in workflow):**
```javascript
const config = {
  AI_PROVIDER: "gigachat",
  CONTENT_SOURCE: "url",
  LLM_MODEL: "GigaChat-2-Max",
  LLM_TEMPERATURE: 0.1,
  LLM_SYSTEM_PROMPT: "...",
  LLM_USER_PROMPT: "...",
  LIMIT_TEXT_LENGTH: 12000,
  LIMIT_PROMPT_LENGTH: 5000,
  LIMIT_MESSAGE_LENGTH: 4096,
  // ... other config
};
```

**Documentation (.env.example):**
- ✅ Correctly states: "NOT USED - hardcoded in workflow"
- ✅ Comment explains: "Для изменения этих параметров отредактируйте Code node 'Configuration'"

**Discrepancy:** ✅ **MATCH** (documentation correctly explains hardcoded config)

---

## 6. Architecture Decisions

### 6.1. Logging Implementation

**Factual SOT:**
- **Pattern:** Execute Workflow nodes for each logging point
- **Log Writer workflow:** Separate reusable workflow
- **Storage:** PostgreSQL table `workflow_logs`
- **Request correlation:** UUID v4 generated once per request
- **Chronological order:** `created_at` passed from Generate Request ID node

**Documentation:**
- ✅ architecture.md mentions PostgreSQL for logs
- ✅ logging-integration-guide.md documents pattern
- ✅ workflow_overview.md mentions logging

**Discrepancy:** ✅ **MATCH**

### 6.2. Error Handling

**Factual SOT:**
- **Pattern:** Continue on Fail for HTTP nodes
- **Error flows:** Separate branches for each error type
- **User messages:** Russian language, user-friendly
- **Error logging:** Execute Workflow nodes for error events

**Documentation:**
- ✅ workflow_overview.md documents error handling
- ✅ architecture.md mentions error flows

**Discrepancy:** ✅ **MATCH**

---

## 7. Project Structure

### 7.1. Directory Structure

**Factual SOT:**
```
telegram-ai-gateway/
├── .env.example
├── .gitignore
├── LICENSE
├── MEMORY.md
├── PROJECT_GOAL.md
├── README.md
├── assets/
│   └── screenshots/
├── attachments/
│   ├── input/
│   └── reports/
├── docker-compose.yml
├── docker-compose.test.yml
├── docs/
│   ├── architecture.md
│   ├── credentials-setup.md
│   ├── deployment_guide.md
│   ├── engineering-investigation-n8n-update.md
│   ├── IMPLEMENTATION_PLAN.md
│   ├── known_issues.md
│   ├── limitations.md
│   ├── logging-integration-guide.md
│   ├── PROJECT_STATE.md
│   ├── setup.md
│   ├── SPEC.md
│   └── workflow_overview.md
├── migrations/
│   ├── 001_create_workflow_logs.sql
│   └── 002_alter_workflow_logs_created_at.sql
├── n8n_files/
├── scripts/
│   └── validate-deployment.sh
├── task_history/
└── workflows/
    ├── Telegram AI Gateway.json
    └── Telegram AI Gateway - Log Writer.json
```

**Documentation:** Not explicitly documented as full structure

**Discrepancy:** ⚠️ Minor gap (project structure not documented)

---

## 8. Critical Findings

### 8.1. Undocumented Configuration Nodes

**Issue:** Two If nodes are not documented in workflow_overview.md:
- **Content Source Detection** — checks `CONTENT_SOURCE === "url"`
- **Provider Entry Point** — checks `AI_PROVIDER === "gigachat"`

**Impact:** 
- These nodes are part of extensible architecture
- Future providers/content sources will use these routing points
- Documentation gap makes architecture harder to understand

**Recommendation:** Add these nodes to workflow_overview.md with explanation of their purpose for extensibility.

### 8.2. Incomplete Logging Documentation

**Issue:** workflow_overview.md does not document all 11 logging points

**Impact:**
- Developers cannot see complete logging coverage
- Difficult to understand what events are logged
- Maintenance becomes harder

**Recommendation:** Add complete list of logging points with their stages and purposes.

### 8.3. Missing Test Configuration Documentation

**Issue:** docker-compose.test.yml is not documented

**Impact:**
- Test environment configuration is unclear
- Differences from production are not explained
- Validation procedures reference test environment but setup is not documented

**Recommendation:** Add test environment documentation to deployment_guide.md or create separate test-guide.md.

---

## 9. Major Findings

### 9.1. Configuration Node Not Documented

**Issue:** The "Configuration" Code node is not explicitly documented in workflow_overview.md

**Impact:**
- Hardcoded configuration parameters are not explained
- Connection between .env.example comments and actual config is not clear

**Recommendation:** Add Configuration node to workflow_overview.md with explanation of hardcoded values.

### 9.2. Workflow Overview Missing Nodes

**Issue:** workflow_overview.md does not document:
- Check Token
- Content Source Detection
- Provider Entry Point

**Impact:**
- Architecture appears simpler than it is
- Extensibility points are not visible
- Future development may miss these routing points

**Recommendation:** Complete node documentation in workflow_overview.md.

### 9.3. Logging Points Not Enumerated

**Issue:** No single document provides complete list of all 11 logging points

**Impact:**
- Logging coverage is unclear
- Audit trail completeness is not obvious
- Troubleshooting is harder

**Recommendation:** Create logging-points.md or add complete list to logging-integration-guide.md.

### 9.4. Project Structure Not Documented

**Issue:** No document provides complete project structure overview

**Impact:**
- New developers need to explore files manually
- Unclear where to find specific components
- Onboarding takes longer

**Recommendation:** Add project structure diagram to architecture.md.

### 9.5. Test Environment Differences

**Issue:** docker-compose.test.yml differences from production are not explained

**Impact:**
- Test/prod parity is unclear
- Validation procedures may miss environment-specific issues
- CI/CD setup is not documented

**Recommendation:** Document test environment setup and differences.

---

## 10. Minor Findings

### 10.1. Docker Compose Version Not Documented

**Issue:** version: '3.8' is not explicitly documented

**Impact:** Minimal

**Recommendation:** Add to deployment_guide.md.

### 10.2. Node Type Distribution Not Shown

**Issue:** No visualization of node type distribution

**Impact:** Understanding workflow complexity requires counting nodes manually

**Recommendation:** Add node type summary to workflow_overview.md.

### 10.3. Error Handling Node Count

**Issue:** workflow_overview.md says "6 for error handling" but actual count is more complex

**Impact:** Minor confusion

**Recommendation:** Clarify error handling node count and distribution.

### 10.4. .env.test File Not Documented

**Issue:** .env.test exists but is not mentioned in documentation

**Impact:** Test environment secrets management is unclear

**Recommendation:** Add test environment documentation.

---

## 11. Summary Table

| Aspect | Factual SOT | Documentation | Status |
|--------|-------------|---------------|--------|
| **n8n version** | 2.29.8 | 2.29.8 | ✅ Match |
| **PostgreSQL version** | 15-alpine | PostgreSQL 15 | ✅ Match |
| **Total workflow nodes** | 39 | 39 | ✅ Match |
| **If nodes** | 7 | 4 documented | ⚠️ Gap |
| **Logging points** | 11 | Partial | ⚠️ Gap |
| **Credentials** | 3 | 3 | ✅ Match |
| **Migrations** | 2 | 2 | ✅ Match |
| **Hardcoded config** | Yes | Documented | ✅ Match |
| **Test config** | Exists | Not documented | ⚠️ Gap |
| **Project structure** | Complex | Not documented | ⚠️ Gap |

---

## 12. Recommendations

### High Priority

1. **Complete workflow_overview.md:**
   - Add Content Source Detection node
   - Add Provider Entry Point node
   - Add Check Token node
   - Add Configuration node
   - Document all 11 logging points

2. **Document test environment:**
   - Create test-guide.md or add to deployment_guide.md
   - Explain docker-compose.test.yml differences
   - Document .env.test purpose

3. **Document project structure:**
   - Add directory tree to architecture.md
   - Explain each directory purpose

### Medium Priority

4. **Enhance logging documentation:**
   - Add complete logging points enumeration
   - Add logging flow diagram
   - Add query examples

5. **Clarify configuration:**
   - Explain hardcoded vs .env parameters
   - Add configuration decision rationale

### Low Priority

6. **Add node type distribution:**
   - Visual summary in workflow_overview.md

7. **Document Docker Compose version:**
   - Add to deployment_guide.md

---

## 13. Files Analyzed

**Workflows:**
- workflows/Telegram AI Gateway.json (3135 lines, 39 nodes)
- workflows/Telegram AI Gateway - Log Writer.json (138 lines, 4 nodes)

**Docker:**
- docker-compose.yml
- docker-compose.test.yml

**Migrations:**
- migrations/001_create_workflow_logs.sql
- migrations/002_alter_workflow_logs_created_at.sql

**Configuration:**
- .env.example
- .env.test

**Documentation:**
- docs/workflow_overview.md
- docs/architecture.md
- docs/credentials-setup.md
- docs/deployment_guide.md
- docs/logging-integration-guide.md
- README.md

**Total:** 15 files analyzed

---

## 14. Verification Method

This report is based on:
1. **Direct code/config analysis** — JSON parsing, YAML parsing, SQL analysis
2. **Text extraction** — grep, awk for documentation
3. **Cross-reference validation** — comparing actual vs documented

No assumptions were made. All findings are based on actual file contents.

---

**End of Report**