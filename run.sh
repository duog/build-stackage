#!/usr/bin/env bash

set -e

BUILD_PLAN=

# TODO: use these to configure whether tests/benchmarks/haddock run
SKIP_TESTS=
SKIP_BENCHMARKS=
SKIP_HADDOCK=YES
SKIP_HOOGLE=YES
# build output (package db, logs, docs) goes here
WORK_DIR=work
# The compiler to test. There must be a matching entry in stack.yaml/setup-info
TEST_COMPILER=ghc-8.2.1.20170929
# defaults to number of processors
JOBS=$(nproc)
OUTPUT_FILE="${WORK_DIR}/stackage-curator-install.log"

# build output (package db, logs, docs) goes here
mkdir -p ${WORK_DIR}
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


echo "========================================================="
echo "Building stackage curator with: $(stack ghc -- --version)"
echo "========================================================="
stack build stackage-curator

if [[ "${BUILD_PLAN:-x}" == "x" ]]; then

    echo "========================================================="
    echo "Creating Build plan ${WORK_DIR}/plan.yaml from https://raw.githubusercontent.com/fpco/stackage/master/build-constraints.yaml"
    echo "========================================================="
    # stackage-curator check seems to need this, this is easier than fixing the bug
    mkdir -p .stack-work/docker/_home/.stack/indices/Hackage
    cp ~/.stack/indices/Hackage/* .stack-work/docker/_home/.stack/indices/Hackage -fr

    stack exec -- stackage-curator check

    BUILD_PLAN="${WORK_DIR}/plan.yaml"
    mv check-plan.yaml "${BUILD_PLAN}"
else

    echo "========================================================="
    echo "Using build plan: ${BUILD_PLAN}"
    echo "========================================================="
fi

echo "========================================================="
echo "Doing the build. Logging output to ${OUTPUT_FILE}"
echo "========================================================="

stack exec -- stackage-curator fetch --plan-file "${BUILD_PLAN}"

echo "### running stackage-curator install at $(date)" >> ${OUTPUT_FILE}
# run stackage-curator inside the docker image, with the release candidate ghc in the path
stack --compiler ${TEST_COMPILER} exec --no-ghc-package-path -- stackage-curator install \
      --build-plan "${BUILD_PLAN}" \
      --jobs ${JOBS} \
      ${SKIP_HADDOCK:+--skip-haddock} \
      ${SKIP_TESTS:+--skip-tests} \
      ${SKIP_BENCHMARKS:+--skip-benchs} \
      ${SKIP_HOOGLE:+--skip-hoogle} \
      --enable-executable-dynamic \
      ${WORK_DIR} 2>&1 | tee -a "${OUTPUT_FILE}"
