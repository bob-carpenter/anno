# anno_fns.R 
# general functions to assemble 
# and assemble data.frames and lists for stan program

# libraries
library(rstan);

library("ggplot2")
library("grid");
library("reshape")

# max_index:  helper function
# returns index of highest value item in a vector
# in case of ties, returns lowest idx
max_index <- function(v) {
  max_index <- 1;
  for (n in 2:length(v))
    if(v[n] > v[max_index])
      max_index <- n;
  return(max_index);
}

plurality_vote_p <- function(v) {
  return (v[max_index(v)]/sum(v));
}


# data file format:  tab separated values, 3 columns, header row
# question rater judgment
# 1 1 1
# 1 2 1
# ...

# get_data:  read in data file, return list
get_data = function(filename) { 
  data <- read.table(filename,header=T,sep="\t");
  dfData <- as.data.frame(data);
  colnames(dfData) <- c("item","annotator","label");
  return(dfData);
};

get_votes <- function(dfData) {
  data <- as.matrix(dfData);
  I=max(dfData$item);
  J=max(dfData$annotator);
  K=max(dfData$label);
  N=dim(data)[1];

  # all category votes per item
  votes <- matrix(0,I,K);
    for (n in 1:N) {
      votes[data[n,1],data[n,3]] <- votes[data[n,1],data[n,3]] + 1;
    }
  cnames <- colnames(votes,do.NULL=FALSE, prefix="cat");
  colnames(votes) <- cnames;
  dfVotes <- as.data.frame(votes);

  zVote <- apply(votes,1,max_index);
  z <- matrix(zVote,ncol=1);
  colnames(z) <- c("zVote");
  dfVotes <- cbind(dfVotes,z);

  zPvp <- apply(votes,1,plurality_vote_p);
  z <- matrix(zPvp,ncol=1);
  colnames(z) <- c("zPvp");
  dfVotes <- cbind(dfVotes,z);

  return(dfVotes);
}


# plot_ipa: return barplot of items per annotator
plot_ipa = function(dfData) {
  tableIPA <- as.matrix(sort(table(dfData$annotator)[]),ncol=1);
  dfIPA <- melt(tableIPA);
  pIPA <- ggplot(dfIPA,aes(x=X1,y=value)) +
          geom_bar(stat="identity",position="dodge") +
          theme_bw() +
          theme(axis.title.x=element_blank(), 
                axis.title.y=element_blank()) +
          labs(title="Items Annotated Per Annotator");
  return (pIPA);
}

# plot_pvp: return histogram of proportion of votes garnered by plurality voted category
plot_pvp = function(dfData) {
    # histogram of proportion votes for plurality category per item
    # pluralityVotePercentage - proportion of votes cast for winning category per item
    pPVP <- ggplot(dfData,aes(x=factor(zPvp))) + 
            geom_histogram(binwith=20) +
            theme_bw() +
            theme(axis.title.x=element_blank(), 
                  axis.title.y=element_blank()) +
            labs(title="Historgram of Proportion Votes for Plurality Voted Category");
    return(pPVP);
}

# summarize_data:  generate summaries and plots 
# over data frame of tuples {item,annotator,label}
# this function generates the plots on whatever
# the current plot device is.
# up to caller to capture this to file.
summarize_data = function(dfData) {
  # text:  I = total items
  #        J =  total annotators, 
  #        K = total labels
  #        N = total annotations
  # raw prevelance of labels: histogram?

  print(plot_ipa(dfData));
  votes <- get_votes(dfData);
  print(plot_pvp(votes));
}
