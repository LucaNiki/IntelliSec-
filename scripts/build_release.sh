#!/usr/bin/env bash
set -e
# Builds Docker images and creates a release tarball
docker build -t intellisec/backend:local -f backend/Dockerfile backend
docker build -t intellisec/frontend:local -f frontend/Dockerfile frontend
mkdir -p release
docker save intellisec/backend:local -o release/backend.tar
docker save intellisec/frontend:local -o release/frontend.tar
tar -czf release/intellisec-release.tar.gz release
echo "Release created at release/intellisec-release.tar.gz"
