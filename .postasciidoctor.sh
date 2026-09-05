#!/bin/sh

if [ -d "/target/site" ]; then
    mv /target/guides/* /target/site
else
    mkdir -p /target/site
    mv /target/guides/* /target/site
fi
rm -r /target/guides