Readme.txt for mturk-stems

This is the data created during the crowdsource stemming project described at:
@misc{carp2009:blog,
  author = {Carpenter, Bob and Jamison, Emily and Baldwin, Breck},
  title = {Building a Stemming Corpus: Coding Standards},
  journal = {Lingpipe Blog},
  type = {Blog},
  number = {February 25},
  year = {2009},
  howpublished = {\url{http://lingpipe-blog.com/2009/02/25/stemming-morphology-corpus-coding-standards/}}
}

The goal of this project is to create a crowdsourced corpus to train a stemmer.  The tokens come from set of lowercased alphabetic tokens appearing at least twice in the English section of the Leipzig Corpus.

Data Files:
We selected 1000 random tokens and Bob and Emily stemmed them by hand.
bob-1000.txt	Bob's annotations
emily-1000.txt	Emily's annotations
diff.txt	the diff of bob-1000.txt and emily-1000.txt
adjudicated-1000.txt	Bob and Emily agreed on these final labels.
All of this is described in the blog post.

stems-1000.tsv	mturk labels on 1000 tokens
stems-5000.tsv	mturk labels on 5000 tokens
stems-20000.tsv	mturk labels on 20,000 tokens

longResults	Results of a different MTurk task where Turkers were shown unstemmed/stemmed word pairs, and asked if the stemming was correct or not.  The stemmed words were MTurk labels from an earlier task.  Please see the blog post for a description of a correctly stemmed pair.
