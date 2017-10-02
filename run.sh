#!/usr/bin/env bash

BUILD_PLAN=nightly-2017-09-29
# TODO: use these to configure whether tests/benchmarks/haddock run
BUILD_TESTS=
BUILD_BENCHMARKS=
BUILD_HADDOCK=

# build output (package db, logs, docs) goes here
WORK_DIR=work
# The compiler to test. There must be a matching entry in stack.yaml/setup-info
TEST_COMPILER=ghc-8.2.1.20170929
JOBS=4

echo "===================="
echo "Pulling docker image"
echo "===================="
stack docker pull

echo "========================================================="
echo "Building stackage curator with: $(stack ghc -- --version)"
echo "========================================================="

stack install --install-ghc

echo "=============================================="
echo "Installing ghc release candidate: ${COMPILER}"
echo "=============================================="
stack --compiler ${TEST_COMPILER} setup

# build output (package db, logs, docs) goes here
mkdir -p $WORK_DIR

pushd $WORK_DIR
# This assumes a nightly build plan
BUILD_PLAN_URL="https://github.com/fpco/stackage-nightly/raw/master/${BUILD_PLAN}.yaml"
echo "============================================"
echo "Retreiving build plan from ${BUILD_PLAN_URL}"
echo "============================================"
curl -LO ${BUILD_PLAN_URL}
popd

# run stackage-curator inside the docker image, with the release candidate ghc in the path
stack --compiler ${TEST_COMPILER} exec --no-ghc-package-path -- stackage-curator install \
      --build-plan "${WORK_DIR}/${BUILD_PLAN}.yaml" \
      --jobs ${JOBS} \
      --enable-executable-dynamic \
      --patch-dir patches \
      ${WORK_DIR}
