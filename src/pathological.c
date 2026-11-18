#include "pg_prelude.h"

PG_MODULE_MAGIC;

static int commit_delay_ms = 0;
static ProcessUtility_hook_type prev_hook = NULL;

void _PG_init(void);

static void pathological_hook(PROCESS_UTILITY_PARAMS) {
  Node *stmt = pstmt->utilityStmt;

  switch (nodeTag(stmt)) {
  case T_TransactionStmt: {
    TransactionStmt *tstmt = (TransactionStmt *)stmt;
    if (commit_delay_ms > 0 && tstmt->kind == TRANS_STMT_COMMIT)
      DirectFunctionCall1(pg_sleep, Float8GetDatum(commit_delay_ms / 1000.0));
    break;
  }
  default:
    break;
  }

  if (prev_hook)
    prev_hook(pstmt, queryString, readOnlyTree, context, params, queryEnv, dest,
              qc);
  else
    standard_ProcessUtility(PROCESS_UTILITY_ARGS);
}

void _PG_init(void) {
  DefineCustomIntVariable("pg_pathological.commit_delay",
                          "Delay COMMIT statements", NULL, &commit_delay_ms, 0,
                          0, INT_MAX, PGC_USERSET, GUC_UNIT_MS, NULL, NULL,
                          NULL);

  prev_hook = ProcessUtility_hook;
  ProcessUtility_hook = pathological_hook;
}
