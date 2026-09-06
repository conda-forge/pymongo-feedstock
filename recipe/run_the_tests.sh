#!/bin/bash
set -ex
# We don't run on PPC64LE + PYPY the full tests due to legacy errors
# https://github.com/conda-forge/pymongo-feedstock/pull/33
# The selector on this test lives in recipe.yaml.
unset REQUESTS_CA_BUNDLE
unset SSL_CERT_FILE

# rattler-build does not define SRC_DIR in the test environment, so use a
# temporary directory for mongod's state instead.
MONGO_TMP_DIR="$(mktemp -d)"

export DB_PATH="${MONGO_TMP_DIR}/temp-mongo-db"
export LOG_PATH="${MONGO_TMP_DIR}/mongolog"
export DB_PORT=27272
export PID_FILE_PATH="${MONGO_TMP_DIR}/mongopidfile"

mkdir "$DB_PATH"

mongod --dbpath="$DB_PATH" --fork --logpath="$LOG_PATH" --port="$DB_PORT" --pidfilepath="$PID_FILE_PATH"

# Run only the synchronous unified-format tests. The full suite contains
# timing-sensitive tests that flake on slow CI (e.g. TestPoolBackpressure).
python -m pytest -v test/test_unified_format.py

# Terminate the forked process after the test suite exits
kill `cat $PID_FILE_PATH`
