#!/bin/bash
#
# Assumes that we're running on Linux with GNU Tar supporting xattrs,
# and a filesystem that does too... for example, not on MacOS... :-(

set -ex

rm *.tar *.txt

rm -f hello 
echo "world" > hello
attr -s abc -V defghij hello

tar --xattrs -v -c -f hello1.tar hello

sed -b -e 's/abc=defghij/abcde=fghij/g' < hello1.tar > hello2.tar

xxd -a hello1.tar > hello1.txt
xxd -a hello2.tar > hello2.txt

rm -f hello

tar -tvf hello1.tar && echo $?
tar -tvf hello2.tar && echo $?
