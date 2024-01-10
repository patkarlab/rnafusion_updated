#! /usr/bin/bash

infile=$1
sed -i 's/\=/-/g' ${infile}
