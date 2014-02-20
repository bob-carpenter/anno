# plot_pvp.R  
# generates grid of plots
# Proportion Votes Plurality Category

library("ggplot2");
library("grid");

max_index <- function(v) {
  max_index <- 1;
  for (n in 2:length(v))
    if(v[n] > v[max_index])
      max_index <- n;
  return(max_index);
}

dataDir <- path.expand("~/projects/anno/data/amt-sense-mt-2013/munged");
plotDir <- path.expand("~/projects/anno/data/amt-sense-mt-2013/plots");

# get list of all words annotated
# if you want a subset of the words, hardcode list instead
wordFiles <- list.files(path=dataDir,pattern = "\\.tsv");
W <- length(wordFiles);
words <- wordFiles;

# columns for data frame
labelsPVP <- vector();
ctsPVP <- vector();


# fill in columns, word by word
for (w in 1:W) {
    print(w);
    words[w] <- sub("\\.[[:alnum:]]+$", "",words[w]);
    words[w] <- sub("[[:punct:]]", "_",words[w]);
    print(words[w]);

    # assume data looks like
    # question,rater,judgment
    # 1,1,1
    # 1,2,1
    # ...

    dataFile = file.path(dataDir,wordFiles[w],fsep=.Platform$file.sep);
    data <- read.table(dataFile,header=T,comment.char='#');
    
    # break apart data
    ii <- data[,1];    # item for labels
    jj <- data[,2];    # annotator for labels
    y <- data[,3];     # labels

    I <- max(ii);      # number of items
    J <- max(jj);      # number of annotators
    K <- max(y);       # number of categories
    N <- dim(data)[1]; # total number of observations

    # jjCategories: tabulate observations, row=annotator, column=category
    jjCategories <- matrix(0,J,K);
    for (n in 1:N)
      jjCategories[jj[n],y[n]] <- jjCategories[jj[n],y[n]] + 1;
    
    # piVoted: word sense prevelence according to observations
    piVoted <- rep(0,K);
    for (n in 1:N)
      piVoted[y[n]] <- piVoted[y[n]] + 1;
    piVoted <- piVoted / sum(piVoted)
    
    # votes per item
    votes <- matrix(0,I,K);
    for (n in 1:N)
      votes[ii[n],y[n]] <- votes[ii[n],y[n]] + 1;
    
    # majority voted per item
    zVote <- rep(0,I);
    for (i in 1:I)
      zVote[i] <- max_index(votes[i,]);
    
    # pluralityVotePercentage - proportion of votes cast for winning category per item
    pluralityVotePercentage <- rep(NA,I);
    for (i in 1:I)
      pluralityVotePercentage[i] <- votes[i,zVote[i]] / sum(votes[i,]); 

    labelsPVP <- c(labelsPVP,rep(words[w],I));
    ctsPVP <- c(ctsPVP,pluralityVotePercentage);

}

# combine into data frame for ggplot
dfPVP <- data.frame(labelsPVP);
dfPVP <- cbind(dfPVP,ctsPVP);

# generate plots
pdfPVP = file.path(plotDir,"ProportionVotesPluralityCategory.pdf",fsep=.Platform$file.sep);
pdf(file=pdfPVP);

# plots a grid 6 cols, 8 rows
gridPlotPVP <- qplot(ctsPVP,data=dfPVP,geom="histogram",
                     binwidth = 0.05,cex.axis=0.2,
                     xlab="pct agreement",ylab="items",
                     main="Proportion of Votes for the Category with the Largest Number of Votes") + 
                     facet_wrap(~ labelsPVP,ncol=6,nrow=8) + 
                     theme(plot.margin = unit(c(0.1,0.2,0.1,0), "cm"));
print(gridPlotPVP);
dev.off();

