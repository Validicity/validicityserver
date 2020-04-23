export PGPASSWORD="validicity"
export PGUSER="validicity"
pg_dump -Fc validicity > $1
