SELECT schemaname,relname,n_live_tup
  FROM pg_stat_user_tables
  ORDER BY n_live_tup DESC;