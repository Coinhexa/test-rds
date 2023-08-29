#!/usr/bin/env bash
 
# Unofficial Bash Strict Mode
# http://redsymbol.net/articles/unofficial-bash-strict-mode/
# https://gist.github.com/vncsna/64825d5609c146e80de8b1fd623011ca
# https://stackoverflow.com/a/35800451/5371505
set -eEuox pipefail
IFS=$'\n\t'
# End of Unofficial Bash Strict Mode#!/usr/bin/env bash

cat <<EOT >> ~/.pgpass
test-chdb.cvagccap4gx8.us-east-1.rds.amazonaws.com:26189:coinhexa_api_db:coinhexa_api_user:password
test-chdb.cvagccap4gx8.us-east-1.rds.amazonaws.com:26189:coinhexa_api_db:postgres:password
test-chdb.cvagccap4gx8.us-east-1.rds.amazonaws.com:26189:ec2-user:coinhexa_api_user:password
test-chdb.cvagccap4gx8.us-east-1.rds.amazonaws.com:26189:ec2-user:postgres:password
test-chdb.cvagccap4gx8.us-east-1.rds.amazonaws.com:26189:postgres:postgres:password
test-chdb.cvagccap4gx8.us-east-1.rds.amazonaws.com:26189:rdsadmin:postgres:password
test-chdb.cvagccap4gx8.us-east-1.rds.amazonaws.com:26189:template1:postgres:password
EOT

# https://stackoverflow.com/a/50563357/5371505
sudo chmod 600 ~/.pgpass
sudo chown ec2-user:ec2-user ~/.pgpass
