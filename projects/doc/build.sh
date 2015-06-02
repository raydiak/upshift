#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd "$DIR"
upshift .

if [ $? -eq 0 ]; then
    cp -v gen/README ../..
fi
