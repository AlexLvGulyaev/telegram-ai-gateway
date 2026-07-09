-- Migration: Alter workflow_logs created_at to remove DEFAULT
-- Version: 2.0
-- Date: 2026-07-09
-- Purpose: Remove DEFAULT CURRENT_TIMESTAMP from created_at to allow passing from n8n
--          This fixes race condition where logs are recorded in wrong chronological order
--
-- Breaking change: After this migration, all INSERT operations MUST provide created_at value
-- Workflow must be updated to pass created_at from Generate Request ID node

-- Remove DEFAULT constraint
ALTER TABLE workflow_logs
ALTER COLUMN created_at DROP DEFAULT;

-- Add NOT NULL constraint (existing rows already have values from DEFAULT)
ALTER TABLE workflow_logs
ALTER COLUMN created_at SET NOT NULL;

-- Update comment to reflect new behavior
COMMENT ON COLUMN workflow_logs.created_at IS 'Timestamp when the log entry was created. MUST be provided by the workflow (passed from Generate Request ID node). No longer defaults to CURRENT_TIMESTAMP to ensure chronological order of logs within a request.';

-- Verification query (should return 0 rows if all existing logs have created_at)
-- SELECT COUNT(*) FROM workflow_logs WHERE created_at IS NULL;
-- Expected: 0