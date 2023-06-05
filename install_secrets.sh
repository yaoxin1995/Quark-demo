#!/bin/bash
set -e 
mkdir -p nginx_resource
mkdir -p /opt/confidential-containers/kbs/repository/quark_nginx

pushd secret
for filename in *; do
cat $filename | base64 | tr -d '\n' > ../nginx_resource/$filename
done
popd

cp -R nginx_resource  /opt/confidential-containers/kbs/repository/quark_nginx

