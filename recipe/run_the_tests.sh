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

# The conda-forge mongodb package for osx-64 ships an arm64 mongod that
# cannot run on an x86_64 macOS host ("Bad CPU type in executable"). On
# macOS, download the upstream server tarball instead. On Linux, use the
# conda-forge mongodb package from PATH.
if [ "$(uname -s)" = "Darwin" ]; then
    MONGO_VERSION=7.0.17
    case "$(uname -m)" in
        x86_64) url="https://fastdl.mongodb.org/osx/mongodb-macos-x86_64-${MONGO_VERSION}.tgz" ;;
        arm64)  url="https://fastdl.mongodb.org/osx/mongodb-macos-arm64-${MONGO_VERSION}.tgz" ;;
        *) echo "Unsupported macOS arch: $(uname -m)" >&2; exit 1 ;;
    esac
    curl --retry 3 -sS --max-time 300 --retry-all-errors "$url" --output mongodb-binaries.tgz
    tar xfz mongodb-binaries.tgz
    rm -f mongodb-binaries.tgz
    mv mongodb-macos-* mongodb
    chmod -R +x mongodb
    MONGOD="./mongodb/bin/mongod"
else
    MONGOD="mongod"
fi

"$MONGOD" --version
"$MONGOD" --dbpath="$DB_PATH" --fork --logpath="$LOG_PATH" --port="$DB_PORT" --pidfilepath="$PID_FILE_PATH"

python -m pytest -v -k "not TestClient and not ClientUnitTest and not test_concurrency and not test_generic_arguments" || python -m pytest --lf -v

# Terminate the forked process after the test suite exits
kill `cat $PID_FILE_PATH`
