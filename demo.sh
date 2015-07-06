#!/bin/bash

set -e

rm -rf bin pkg
mkdir  bin pkg

export GOPATH=$(pwd)

go fmt     -x demo
go install -v demo

pushd demo
./create.sh
popd

for FILE in demo/hello?.tar ; do
	./bin/demo < "$FILE"
done

rm -rf bin/* pkg/*
