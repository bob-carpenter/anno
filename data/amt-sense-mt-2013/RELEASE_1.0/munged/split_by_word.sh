#/bin/sh
for x in `cat words.txt`; 
do echo $x; 
grep -w $x annotations.tsv > annotations_$x.tsv; 
wc -l annotations_$x.tsv; 
done

