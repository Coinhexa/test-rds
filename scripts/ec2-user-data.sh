#!/usr/bin/env bash
 
# Unofficial Bash Strict Mode
# http://redsymbol.net/articles/unofficial-bash-strict-mode/
# https://gist.github.com/vncsna/64825d5609c146e80de8b1fd623011ca
# https://stackoverflow.com/a/35800451/5371505
set -eEuox pipefail
IFS=$'\n\t'
# End of Unofficial Bash Strict Mode

# Update all packages
yum update -y

# Install node.js 16x
curl -sL https://rpm.nodesource.com/setup_16.x | sudo bash -
yum install -y nodejs git

# Download repo and install dependencies
cd /home/ec2-user
git clone https://github.com/Coinhexa/test-rds
chown -R ec2-user:ec2-user ./test-rds
cd /home/ec2-user/test-rds
npm install

# Install psql and pg_dump
amazon-linux-extras install -y postgresql14
echo test-chdb.cvagccap4gx8.us-east-1.rds.amazonaws.com:26189:coinhexa_api_db:postgres:password > ~/.pgpass

# https://stackoverflow.com/a/50563357/5371505
chmod 600 ~/.pgpass
sudo chown ec2-user:ec2-user ~/.pgpass
export PGPASSFILE='/home/ec2-user/.pgpass'
psql "host=test-chdb.cvagccap4gx8.us-east-1.rds.amazonaws.com port=26189 dbname=coinhexa_api_db user=postgres sslrootcert=/home/ec2-user/api/docker/production/postgres_server_certs/rds-ca-rsa2048-g1.pem sslmode=verify-full"
