-- Migration: Create workflow_logs table
-- Version: 1.0
-- Date: 2026-07-09
-- Purpose: Store execution logs for Telegram AI Gateway workflow
--
-- This table enables complete request lifecycle tracking and audit trail.
-- Every significant workflow event is logged with full context.

CREATE TABLE IF NOT EXISTS workflow_logs (
    -- Primary key
    id SERIAL PRIMARY KEY,

    -- Timestamp (indexed for time-based queries)
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    -- Request correlation (indexed for request tracking)
    request_id UUID NOT NULL,

    -- Workflow identification
    workflow_name VARCHAR(255) NOT NULL,
    workflow_version VARCHAR(50),

    -- Execution stage
    -- Examples: 'REQUEST_RECEIVED', 'URL_VALIDATED', 'PAGE_LOAD_STARTED', etc.
    stage VARCHAR(100) NOT NULL,

    -- Event type
    -- Examples: 'validation', 'http_request', 'processing', 'telegram_send', etc.
    event_type VARCHAR(100),

    -- Log level
    -- Values: 'INFO', 'WARNING', 'ERROR'
    level VARCHAR(20) NOT NULL DEFAULT 'INFO',

    -- Status
    -- Values: 'SUCCESS', 'FAILED', 'IN_PROGRESS'
    status VARCHAR(50) NOT NULL DEFAULT 'IN_PROGRESS',

    -- User context
    chat_id VARCHAR(100),
    user_id VARCHAR(100),

    -- Input
    input_url TEXT,

    -- Duration (in milliseconds)
    -- Populated for events that have measurable duration
    duration_ms INTEGER,

    -- Human-readable message
    message TEXT,

    -- Error context
    error_code VARCHAR(50),
    error_message TEXT,

    -- Additional details (flexible JSONB for extensibility)
    details JSONB DEFAULT '{}'::jsonb
);

-- Indexes for common queries

-- Index for request_id (essential for request lifecycle tracking)
CREATE INDEX idx_workflow_logs_request_id ON workflow_logs(request_id);

-- Index for created_at (time-based queries, log rotation)
CREATE INDEX idx_workflow_logs_created_at ON workflow_logs(created_at DESC);

-- Index for workflow_name (multi-workflow support in future)
CREATE INDEX idx_workflow_logs_workflow_name ON workflow_logs(workflow_name);

-- Composite index for request_id + created_at (efficient request log retrieval)
CREATE INDEX idx_workflow_logs_request_created ON workflow_logs(request_id, created_at);

-- Index for status (error tracking)
CREATE INDEX idx_workflow_logs_status ON workflow_logs(status);

-- Index for level (filtering by log level)
CREATE INDEX idx_workflow_logs_level ON workflow_logs(level);

-- Comments for documentation
COMMENT ON TABLE workflow_logs IS 'Execution logs for Telegram AI Gateway workflow. Stores every significant event with full context for request lifecycle tracking.';
COMMENT ON COLUMN workflow_logs.request_id IS 'Unique identifier for each workflow execution. Generated once at start, used for correlation across all log events.';
COMMENT ON COLUMN workflow_logs.stage IS 'Workflow execution stage. Examples: REQUEST_RECEIVED, URL_VALIDATED, PAGE_LOAD_STARTED, PAGE_LOADED, etc.';
COMMENT ON COLUMN workflow_logs.event_type IS 'Type of event. Examples: validation, http_request, processing, telegram_send.';
COMMENT ON COLUMN workflow_logs.level IS 'Log level: INFO, WARNING, ERROR.';
COMMENT ON COLUMN workflow_logs.status IS 'Status of the event: SUCCESS, FAILED, IN_PROGRESS.';
COMMENT ON COLUMN workflow_logs.details IS 'Flexible JSONB field for additional context. Can store any structured data without schema changes.';

-- Sample queries for verification:
-- 1. Get all logs for a specific request:
--    SELECT * FROM workflow_logs WHERE request_id = 'some-uuid' ORDER BY created_at;
--
-- 2. Get all failed requests in last 24 hours:
--    SELECT DISTINCT request_id, created_at, error_message
--    FROM workflow_logs
--    WHERE status = 'FAILED' AND created_at > NOW() - INTERVAL '24 hours'
--    ORDER BY created_at DESC;
--
-- 3. Get request lifecycle:
--    SELECT created_at, stage, status, duration_ms, message
--    FROM workflow_logs
--    WHERE request_id = 'some-uuid'
--    ORDER BY created_at;
--
-- 4. Get average processing time:
--    SELECT AVG(duration_ms)
--    FROM workflow_logs
--    WHERE stage = 'WORKFLOW_FINISHED' AND status = 'SUCCESS';