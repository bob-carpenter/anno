#!/bin/sh

# get word names, cts
awk '{print $1}' annotations.tsv | sort -u > words.txt

# break dataset into per-word files
for x in `cat words.txt`
do 
    echo $x
    grep -w $x annotations.tsv | awk '{ii = ($2*10)+$3-1}{print ii,$4,$5}' > annotations_$x.tsv
    wc -l annotations_$x.tsv
done
