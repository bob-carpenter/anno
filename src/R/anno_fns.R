# anno_fns.R 
# general functions to assemble 
# and assemble data.frames and lists for stan program

# libraries
library(rstan);

library("ggplot2")
library("reshape")

# data file format -  tab separated values, 3 columns, header row
# question rater judgment
# 1 1 1
# 1 2 1
# ...

# get_data -  read in data file, return list
get_data = function(filename) { 
  data <- read.table(filename,header=T,sep="\t");
  dfData <- as.data.frame(data);
  colnames(dfData) <- c("item","annotator","label");
  return(dfData);
};

# plurality_vote_p -  helper function
# calculates proportion of votes to most popular item
plurality_vote_p <- function(v) {
  return (v[which.max(v)]/sum(v));
}

get_votes <- function(dfData) {
  data <- as.matrix(dfData);
  I=max(dfData$item);
  J=max(dfData$annotator);
  K=max(dfData$label);
  N=dim(data)[1];

# matrix votes -  tabulate votes per category (colun) per item (row)
  votes <- matrix(0,I,K);
  for (n in 1:N) {
    votes[data[n,1],data[n,3]] <- votes[data[n,1],data[n,3]] + 1;
  }
  cnames <- colnames(votes,do.NULL=FALSE, prefix="cat");
  colnames(votes) <- cnames;
  dfVotes <- as.data.frame(votes);

# column zVote - index in votes of winning category
  zVote <- apply(votes,1,which.max);
  z <- matrix(zVote,ncol=1);
  colnames(z) <- c("zVote");
  dfVotes <- cbind(dfVotes,z);

# column zPvp - proportion of total votes accorded winning category
  zPvp <- apply(votes,1,plurality_vote_p);
  zs <- matrix(zPvp,ncol=1);
  colnames(zs) <- c("zPvp");
  dfVotes <- cbind(dfVotes,zs);

  return(dfVotes);
}

# plot_ipa - return barplot of items per annotator
plot_ipa = function(dfData) {
  tableIPA <- as.matrix(rev(sort(table(dfData$annotator)[])),ncol=1);
  dfIPA <- melt(tableIPA);
  pIPA <- ggplot(dfIPA,aes(x=X1,y=value)) +
          geom_bar(stat="identity",position="dodge") +
          theme(axis.title.x=element_blank(), 
                axis.title.y=element_blank()) +
          labs(title="Items Annotated Per Annotator");
  return (pIPA);
}

# plot_pvp - return histogram of proportion of votes garnered by plurality voted category
# need to make labels smaller
plot_pvp = function(dfVotes) {
  pPVP <- ggplot(dfVotes,aes(x=factor(zPvp))) + 
          geom_histogram() +
          theme(axis.title.x=element_blank(), 
                axis.title.y=element_blank()) +
          scale_x_discrete(breaks = round(seq(0,1,by = 0.2),1)) +
          labs(title="Proportion of Total Votes for Winning Category");
    return(pPVP);
}

# summarize_data -  generate summaries and plots 
# over data frame of tuples {item,annotator,label}
# this function generates the plots on whatever
# the current plot device is.
# up to caller to capture this to file.
summarize_data = function(dfData) {
  print(plot_ipa(dfData));
  votes <- get_votes(dfData);
  print(plot_pvp(votes));
}

# write the N items w/ least amount of agreememnt
write_lowest = function(dfVotes,n,filename) {
  zCol <- dim(dfVotes)[2];
  tmp <- dfVotes[order(dfVotes[,zCol]),];
  write.table(tmp[1:n,],file=filename,append=F,quote=F,col.names=F,sep="\t");
}

