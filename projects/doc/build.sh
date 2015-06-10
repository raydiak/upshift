#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd "$DIR"
../../bin/upshift .

if [ $? -eq 0 ]; then
    diff -u ../../README gen/README
    cp -v gen/README ../..
fi
