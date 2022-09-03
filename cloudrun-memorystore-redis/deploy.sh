#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

. .envrc

version="latest"
tag="asia-northeast1-docker.pkg.dev/${PROJECT_ID}/myapp/myapp:${version}"

docker build -t "${tag}" .
docker push "${tag}"

gcloud run deploy myapp \
  --project "${PROJECT_ID}" \
  --service-account "myapp-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
  --image "${tag}" \
  --allow-unauthenticated \
  --vpc-connector myapp-connector \
  --region asia-northeast1 \
  --update-secrets "REDIS_PLAIN_HOST=myapp-redis-plain-host:latest" \
  --update-secrets "REDIS_AUTH_HOST=myapp-redis-auth-host:latest" \
  --update-secrets "REDIS_AUTH_AUTHSTRING=myapp-redis-auth-authstring:latest" \
  --update-secrets "REDIS_TLS_HOST=myapp-redis-tls-host:latest" \
  --update-secrets "/redis_tls_cert/ca.pem=myapp-redis-tls-cert:latest" \
  --update-secrets "REDIS_AUTHTLS_HOST=myapp-redis-authtls-host:latest" \
  --update-secrets "REDIS_AUTHTLS_AUTHSTRING=myapp-redis-authtls-authstring:latest" \
  --update-secrets "/redis_authtls_cert/ca.pem=myapp-redis-authtls-cert:latest"
