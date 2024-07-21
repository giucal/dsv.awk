#!/bin/sh

awk -f test/before.awk -f dsv.awk -f test/after.awk test/cases.txt