# viz.R  visualize data

library("ggplot2");
library("grid");
library("RColorBrewer");

max_index <- function(v) {
  max_index <- 1;
  for (n in 2:length(v))
    if(v[n] > v[max_index])
      max_index <- n;
  return(max_index);
}

dataDir <- path.expand("~/anno/data/amt-sense-mt-2013/munged");
plotDir <- path.expand("~/anno/data/amt-sense-mt-2013/plots");

wordFiles <- list.files(path=dataDir,pattern = "\\.tsv");
W <- length(wordFiles);
words <- wordFiles;

# lists of itemsPerAnnotator

labelsIPA <- vector();
ctsIPA <- vector();
sensesIPA <- vector();

labelsPVP <- vector();
ctsPVP <- vector();

votesPerWord <- vector();

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
    
    # DATA
    ii <- data[,1];    # item for labels
    jj <- data[,2];    # annotator for labels
    y <- data[,3];     # labels

    I <- max(ii);      # number of items
    J <- max(jj);      # number of annotators
    K <- max(y);       # number of categories
    N <- dim(data)[1]; # total number of observations

    votesPerWord <- c(votesPerWord, N);

    # jjHitCts: raw cts annotations per annotator 
    jjHitCts <- rep(0,J);
    for (n in 1:N)
      jjHitCts[jj[n]] <- jjHitCts[jj[n]] + 1;
    
    labelsIPA <- c(labelsIPA,rep(words[w],J));
    ctsIPA <- c(ctsIPA,jjHitCts);
    sensesIPA <- c(sensesIPA,c(1:J));


    # jjCategories: per-annotator total votes per category
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

dfIPA <- data.frame(labelsIPA);
dfIPA <- cbind(dfIPA,ctsIPA);
dfIPA <- cbind(dfIPA,sensesIPA);


dfPVP <- data.frame(labelsPVP);
dfPVP <- cbind(dfPVP,ctsPVP);

pngIPA = file.path(plotDir,"ItemsPerAnnotator.png",fsep=.Platform$file.sep);
png(file=pngIPA);
gridPlotIPA <- qplot(ctsIPA,data=dfIPA,geom="histogram",
                     binwidth = 20,cex.axis=0.2,ylim=c(0,20),
                     xlab="items",ylab="annotators",main="Items Annotated per Annotator") + 
                     facet_wrap(~ labelsIPA,ncol=6,nrow=8) + 
                     theme(plot.margin = unit(c(0.1,0.2,0.1,0), "cm"));
print(gridPlotIPA);
dev.off();

pngPVP = file.path(plotDir,"ProportionVotesPluralityCategory.png",fsep=.Platform$file.sep);
png(file=pngPVP);
gridPlotPVP <- qplot(ctsPVP,data=dfPVP,geom="histogram",
                     binwidth = 0.05,cex.axis=0.2,
                     xlab="pct agreement",ylab="items",
                     main="Proportion of Votes for the Category with the Largest Number of Votes") + 
                     facet_wrap(~ labelsPVP,ncol=6,nrow=8) + 
                     theme(plot.margin = unit(c(0.1,0.2,0.1,0), "cm"));
print(gridPlotPVP);
dev.off();

# TODO:  print table qua table (alphabetical by word)
# TODO:  barplot should be sorted
annotators_per_item <- table(dfIPA$labelsIPA);
pngApW = file.path(plotDir,"AnnotatorsPerWord.png",fsep=.Platform$file.sep);
png(file=pngApW);
barplot(rev(annotators_per_item),horiz=TRUE,las=1,
        cex.names=0.5,cex.axis=0.6,xlim=c(10,60),
        main="Annotators per Word",col=brewer.pal(9,"Set3"),space=0.01);
dev.off();

# TODO:  make dots invisible - just label by word
pngAxA = file.path(plotDir,"Annotators_X_Annotations_PerWord.png",fsep=.Platform$file.sep);
png(file=pngAxA);
plot(jitter(votesPerWord),jitter(annotators_per_item[]),
        ylab="annotators",xlab="annotations",main="Annotators x Annotations",pch=20);
text(votesPerWord,annotators_per_item[],labels=names(annotators_per_item),cex=0.5,pos=1);
dev.off();

