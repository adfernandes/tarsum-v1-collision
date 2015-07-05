#!/bin/bash

set -e

rm -rf bin pkg
mkdir  bin pkg

export GOPATH=$(pwd)

go fmt     -x demo
go install -v demo

./bin/demo < demo/hello1.tar
./bin/demo < demo/hello2.tar

rm -rf bin/* pkg/*
