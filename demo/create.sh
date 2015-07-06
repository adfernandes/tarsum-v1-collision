#!/bin/bash
#
# Assumes that we're running on a POSIX-like system where both the
# filesystem and the 'tar' utility both handle extended attributes.

set -ex

rm -f *.tar *.txt

function create_tar
{
	rm -f hello 
	echo "world" > hello
	attr -s "$2" -V "$3" hello
	touch -cam --date "$4" hello
	tar --xattrs -v -c -f "hello$1.tar" hello
	xxd -a "hello$1.tar" > "hello$1.txt"
	rm -f hello 
}

DATE=$(date)

create_tar 1 "a" "bc" "$DATE"
create_tar 2 "ab" "c" "$DATE"
create_tar 3 "abc" "" "$DATE"
