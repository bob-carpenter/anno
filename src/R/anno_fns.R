# anno_fns.R 
# general functions to assemble 
# and assemble data.frames and lists for stan program

# libraries
library(rstan);

library("ggplot2")
library("grid");
library("reshape")
library("RColorBrewer");
library("scales")

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

# data file format:  tab separated values, 3 columns, header row
# question rater judgment
# 1 1 1
# 1 2 1
# ...

# get_data:  read in data file, return list
get_data = function(filename) { 
  data <- read.table(filename,header=T,sep="\t");
  ii <- data[,1];    # item for labels
  jj <- data[,2];    # annotator for labels
  y <- data[,3];     # labels
  dfData <- data.frame(ii,jj,y);
  colnames(dfData) <- c("item","annotator","label");

  return(list(data=dfData,
              I=max(ii),
              J=max(jj),
              K=max(y),
              N=dim(data)[1]));
};


# summarize_data:  generate summaries and plots 
# over data frame of tuples {item,annotator,label}
# this function generates the plots on whatever
# the current plot device is.
# up to caller to capture this to file.
summarize_data = function(lData) {}
  # text:  I = total items
  #        J =  total annotators, 
  #        K = total labels
  #        N = total annotations

  # raw prevelance of labels: histogram?
  # per item prevelance of consensus label


# plotIPA: return barplot of items per annotator (ggggplot)
plotIPA = function(lData) {
  tableIPA <- as.matrix(sort(table(lData$data$annotator)[]),ncol=1);
  dfIPA <- melt(tableIPA);
  pIPA <- ggplot(dfIPA,aes(x=X1,y=value)) +
          geom_bar(stat="identity",position="dodge") +
          theme_bw() +
          theme(axis.title.x=element_blank(), 
                axis.title.y=element_blank()) +
          labs(title="Items Annotated by Annotator");

  return (pIPA);
}

# plotPVP: return histogram of proportion of votes garnered by plurality voted category
plotPVP = function(lData) {
    # all category votes per item
    votes <- matrix(0,lData$I,lData$K);
    for (n in 1:lData$N) {
      item = lData$data[n,1];
      label = lData$data[n,3];
      votes[item,label] <- votes[item,label] + 1;
    }
    
    # majority categoy voted per item
    zVote <- rep(0,lData$I);
    for (i in 1:lData$I)
      zVote[i] <- max_index(votes[i,]);

    # histogram of proportion votes for plurality category per item
    # pluralityVotePercentage - proportion of votes cast for winning category per item
    pluralityVotePercentage <- rep(NA,lData$I);
    for (i in 1:lData$I)
      pluralityVotePercentage[i] <- votes[i,zVote[i]] / sum(votes[i,]); 
    dfPVP <- data.frame(pvp=pluralityVotePercentage);
    pPVP <- ggplot(dfPVP,aes(x=factor(pvp))) + 
            geom_histogram(binwith=20) +
            theme_bw() +
            theme(axis.title.x=element_blank(), 
                  axis.title.y=element_blank()) +
            labs(title="Proportion of votes for plurality voted label");
    return(pPVP);
}


# get_filename:  calls R file.path given dirname, filename
get_filename = function(dirname,filename) {
  return(file.path(path.expand(dirname),
                   filename,
                   fsep=.Platform$file.sep));
};





# vp.layout and arrange_ggplot2 copied from:
# http://gettinggeneticsdone.blogspot.com/2010/03/arrange-multiple-ggplot2-plots-in-same.html

# vp.layout:  helper function defines vieport setting number of rows and columns
vp.layout <- function(x, y) viewport(layout.pos.row=x, layout.pos.col=y);

# arrange_ggplot2:  puts list of plots on one page using viewports
# params: list of plots, nrow=x, ncol=y
# arranges plots on one page
# for nrow=2, ncol=3, plots p1-p6 are arranged
# p1@(r1,c1), p2@(r1,c2), p3@(r1,c3), p4@(r2,c1), p5@(r2,c2), p6@(r2,c3)

arrange_ggplot2 <- function(..., nrow=NULL, ncol=NULL, as.table=FALSE) {
  dots <- list(...);
  n <- length(dots);
  if(is.null(nrow) & is.null(ncol)) { nrow = floor(n/2) ; ncol = ceiling(n/nrow)};
  if(is.null(nrow)) { nrow = ceiling(n/ncol)};
  if(is.null(ncol)) { ncol = ceiling(n/nrow)};

  grid.newpage();
  pushViewport(viewport(layout=grid.layout(nrow,ncol) ) );
  ii.p <- 1;
  for(ii.row in seq(1, nrow)){
    ii.table.row <- ii.row;
    if(as.table) {ii.table.row <- nrow - ii.table.row + 1};
    for(ii.col in seq(1, ncol)){
      ii.table <- ii.p;
      if(ii.p > n) break;
      print(dots[[ii.table]], vp=vp.layout(ii.table.row, ii.col));
      ii.p <- ii.p + 1;
    }
  }
}
