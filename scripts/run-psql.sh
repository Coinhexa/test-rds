#!/usr/bin/env bash
 
# Unofficial Bash Strict Mode
# http://redsymbol.net/articles/unofficial-bash-strict-mode/
# https://gist.github.com/vncsna/64825d5609c146e80de8b1fd623011ca
# https://stackoverflow.com/a/35800451/5371505
set -eEuox pipefail
IFS=$'\n\t'
# End of Unofficial Bash Strict Mode

psql "host=test-chdb.cvagccap4gx8.us-east-1.rds.amazonaws.com port=26189 dbname=coinhexa_api_db user=postgres sslrootcert=/home/ec2-user/api/docker/production/postgres_server_certs/rds-ca-rsa2048-g1.pem sslmode=verify-full"
