#!/bin/sh

if [[ -f Combined.zip ]]; then
    rm Combined.zip
fi;

cat Archive.z* > Combined.zip
unzip Combined.zip
rm Combined.zip
