#!/usr/bin/env bash
 
# Unofficial Bash Strict Mode
# http://redsymbol.net/articles/unofficial-bash-strict-mode/
# https://gist.github.com/vncsna/64825d5609c146e80de8b1fd623011ca
# https://stackoverflow.com/a/35800451/5371505
set -eEuox pipefail
IFS=$'\n\t'
# End of Unofficial Bash Strict Mode

# Update all packages
echo "****************UPDATING PACKAGES****************"

# Update all packages
yum update -y

# Install psql and pg_dump
echo "****************INSTALLING POSTGRES TOOLS****************"

amazon-linux-extras install -y postgresql14
echo test-rdsdb.cvagccap4gx8.us-east-1.rds.amazonaws.com:26189:postgres:postgres:testRDSinstance > /home/ec2-user/.pgpass

echo "****************CREATING PGPASS FILE****************"

# https://stackoverflow.com/a/50563357/5371505
chmod 600 /home/ec2-user/.pgpass
sudo chown ec2-user:ec2-user /home/ec2-user/.pgpass

# Install node.js 16x
echo "****************INSTALLING NODE.JS****************"

# https://github.com/nodesource/distributions
yum install https://rpm.nodesource.com/pub_16.x/nodistro/repo/nodesource-release-nodistro-1.noarch.rpm -y
yum install -y nodejs git

# Download repo and install dependencies
echo "****************INSTALLING TEST-RDS GITHUB REPO****************"

cd /home/ec2-user
git clone https://github.com/Coinhexa/test-rds
chown -R ec2-user:ec2-user ./test-rds
cd /home/ec2-user/test-rds
npm install

echo "****************INSTALLING RDS CERTS****************"

mkdir -p /home/ec2-user/test-rds/certs
curl "https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem" > /home/ec2-user/test-rds/certs/rds-ca-rsa2048-g1.pem
