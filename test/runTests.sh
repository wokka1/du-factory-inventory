#!/bin/sh

# stop for error if test returns non-0 exit code
# set -e

# set return code for final result
exitCode=0

# simplify paths by working from project root
cd "$(dirname "$0")/.."

# clear out old results
rm -rf test/results
mkdir -p test/results/
mkdir -p test/results/images

for test in test/**/Test*.lua
do
    testName=`basename $test`
    lua -lluacov ${test} $@ -n test/results/${testName}.xml

    retVal=$?
    if [ $retVal -ne 0 ]; then
        exitCode=$retVal
    fi
done

exit $exitCode
