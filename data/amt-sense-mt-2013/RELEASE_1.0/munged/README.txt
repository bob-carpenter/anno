Prliminaries: 

We need split annotations.tsv into set of files, one per WordPos (e.g. add-v)
because categories are only meaningful w/r/t particular word,
e.g. category 3 for add-v is not the same as category 3 for work-n.
Therefore column 1 determines output file and output file name.


Tabulate word names, cts
 awk '{print $1}' annotations.tsv | sort -u > words.txt
 awk '{print $1}' annotations.tsv | sort | uniq -c | awk '{print $2, $1} > words_cts.txt

Break dataset into per-word files
 for x in `cat words.txt`; do echo $x; grep -w $x annotations.tsv > annotations_$x.tsv; wc -l annotations_$x.tsv; done

Task 1:

Reformat original data file annotations.tsv into input to Stan model:
itemId(ii) annotatorId(jj) response(k)

Format of original data file:  5 columns
    WordPos
    FormId
    SentenceId
    AnnotatorId
    SenseId

WordPos - we've split annotations.tsv into 45 files, one per WordPos,
and WordPos is now part of file name, e.g.  annotations_add-v.tsv

get ii: itemId is combination of FormId + SentenceId
FormId ranges from 1-100,  SentenceId ranges from 1-10
combine:  FormId*10 + SentenceId - 1 
to convert itemId to formId, sentenceId:
 formId = itemId div 10, sentenceId = (itemId mod 10) + 1

get jj: annotatorIds are global -  we need to create numbering from 1 to J for
just the annotators who annotated this particular word - save map from
jj to global annotatorId.

Task 2:  

Randomly choose k annotations from all n annotations for sentence i
do this in R pre-processing for reproducibility.





