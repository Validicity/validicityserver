export PGPASSWORD="validicity"
export PGUSER="validicity"
pg_restore -c -d validicity $1
