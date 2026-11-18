# pg_pathological

PostgreSQL loadable module for enabling pathological behavior.

## commit_delay

A user setable guc that delays a COMMIT statement.

```sql
LOAD 'pathological';
BEGIN;
SET LOCAL statement_timeout = '50ms';
SET LOCAL pg_pathological.commit_delay = '1s';
COMMIT;
ERROR:  canceling statement due to statement timeout
```

