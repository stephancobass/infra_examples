#!/bin/bash
set -e

#docker build -f local_frontend.Dockerfile -t local_frontend:local .

cd ../..

docker build -f ci/local_backend.Dockerfile -t local_backend:local .

# Check rules ci/local