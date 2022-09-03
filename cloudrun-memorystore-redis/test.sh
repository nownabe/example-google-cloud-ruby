#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

. .envrc

url=$(
gcloud run services describe myapp \
  --project "${PROJECT_ID}" \
  --region asia-northeast1 \
  --format "value(status.url)"
)

echo "Healthcheck"
curl -s "${url}"

echo -e "\nPlain Redis"
curl -s "${url}/plain/set/foo/bar"
curl -s "${url}/plain/get/foo"

echo -e "\nRedis with AUTH"
curl -s "${url}/auth/set/foo/bar"
curl -s "${url}/auth/get/foo"

echo -e "\nRedis with TLS"
curl -s "${url}/tls/set/foo/bar"
curl -s "${url}/tls/get/foo"

echo -e "\nRedis with AUTH and TLS"
curl -s "${url}/authtls/set/foo/bar"
curl -s "${url}/authtls/get/foo"
