#!/bin/bash
set -ex
# We don't run on PPC64LE + PYPY the full tests due to legacy errors
# https://github.com/conda-forge/pymongo-feedstock/pull/33
# That said, I found it very hard to use the 
# target_platform
# and
# python_impl
# variables in the test section.
# Therefore, we simply use the selector in the meta.yaml file.
unset REQUESTS_CA_BUNDLE
unset SSL_CERT_FILE

export DB_PATH="$SRC_DIR/temp-mongo-db"
export LOG_PATH="$SRC_DIR/mongolog"
export DB_PORT=27272
export PID_FILE_PATH="$SRC_DIR/mongopidfile"

mkdir "$DB_PATH"

mongod --dbpath="$DB_PATH" --fork --logpath="$LOG_PATH" --port="$DB_PORT" --pidfilepath="$PID_FILE_PATH"

python setup.py build_ext -i

python -m pytest -v -k "not TestClient" -k "not ClientUnitTest"

# Terminate the forked process after the test suite exits
kill `cat $PID_FILE_PATH`
