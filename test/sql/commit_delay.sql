LOAD 'pathological';
BEGIN;
SET LOCAL statement_timeout = '50ms';
SET LOCAL pg_pathological.commit_delay = '1s';
COMMIT;
