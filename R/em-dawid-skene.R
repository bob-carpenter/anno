######################################################################
# MAP estimates for Dawid and Skene Model with Priors
#
# This code extends the model and EM algorithm presented here:
#
#    A. P. Dawid and A. M. Skene. 1979.  Maximum Likelihood Estimation
#    of Observer Error-Rates Using the EM Algorithm.  Journal of Royal
#    Statistical Society, Series C (Applied Statistics) 28(1):20--28.
#    http://www.jstor.org/stable/2346806?origin=JSTOR-pdf
#
# as described in this paper:
#
#    Rebecca J. Passonneau and Bob Carpenter. 2014.  The Benefits of a
#    Model of Annotation.  Transactions of the Association for
#    Computational Linguistics 2(Oct):311−326.
#    http://www.transacl.org/wp-content/uploads/2014/10/taclpaper60.pdf
#
# USAGE in R:
#
# First change directories to the directory containing this file:
#
#     > setwd("anno/R");  
#
# then run the program:
#
#     > source("em-dawid-skene.R");
#
# You will need to change the hard-coded path in read.table and run
# it with data organized with a header and one row per label
# as (item ID annotator ID category ID) with a single tab separating
# each column.  All identifiers must be numbered sequentially from 1.
# The data from (Passonneau and Carpenter 2014) is included with the
# repo and provides an example.  Here's the head of add-v.tsv:
#
#    item       annotator       rating
#    1  1       6
#    2  1       3
#    3  1       1
#    4  1       3
#    5  1       1
#    6  1       1
#    ...
#
# Upon completion, you will find the following estimands set in
# the global namespace:
#
#   pi_hat[k]:          estimate of pi[k]
#   theta_hat[j,k,k']:  estimate of theta[j,k,k']
#   E_z[i,k]:           estimate of Pr[z[i]==k | data] 
#
# and the program writes three TSV files in the directory from which 
# it was run as output, for prevalence (pi), annotator accuracies
# and biases (theta), and predicted true category (z).
# 
#   pi_hat.tsv          estimate of pi
#   theta_hat.tsv       estimate of theta
#   z_hat.tsv           estimate of Pr[Z[i] == k | data]
#
######################################################################

# PROGRAM VARIABLES
# K: number of cats
# J: number of annotators
# I: number of annotations
# N: number of labels
# ii[N] in 1:I:  item for label n
# jj[N] in 1:J:  annotator for label n
# y[N] in 1:K:   category for label n

### READ DATA

# this next line assumes you read out of GitHub from the R directory
data <- read.table("../data/amt-sense-mt-2013/munged/add-v.tsv",header=TRUE);
print("finished reading data");

ii <- data[[1]];
jj <- data[[2]];
y <- data[[3]];

N <- length(ii);
K <- max(y);
J <- max(jj);
I <- max(ii);

# print data sizes
print(paste("K=",K, "; N=",N, "; J=",J, ";I=",I));

##### EM ALGORITHM #####

### INITIALIZATION
theta_hat <- array(NA,c(J,K,K));
for (j in 1:J)
  for (k in 1:K)
    for (k2 in 1:K)
      theta_hat[j,k,k2] <- ifelse(k==k2, 0.7, 0.3/K);

pi_hat <- array(1/K,K);

### EM ITERATIONS
epoch <- 1;
min_relative_diff <- 1E-8;
last_log_posterior = - Inf;
E_z <- array(1/K, c(I,K));
MAX_EPOCHS <- 100;
for (epoch in 1:MAX_EPOCHS) {
  ### E step 
  for (i in 1:I)
    E_z[i,] <- pi_hat;
  for (n in 1:N)
    for (k in 1:K)
      E_z[ii[n],k] <- E_z[ii[n],k] * theta_hat[jj[n],k,y[n]];
  for (i in 1:I)
    E_z[i,] <- E_z[i,] / sum(E_z[i,]);

  ### M step
  beta <- 0.01; 
  pi_hat <- rep(beta,K);          # add beta smoothing on pi_hat
  for (i in 1:I)
    pi_hat <- pi_hat + E_z[i,];
  pi_hat <- pi_hat / sum(pi_hat);

  alpha <- 0.01;
  count <- array(alpha,c(J,K,K)); # add alpha smoothing for theta_hat
  for (n in 1:N)
    for (k in 1:K)
      count[jj[n],k,y[n]] <- count[jj[n],k,y[n]] + E_z[ii[n],k];
  for (j in 1:J)
    for (k in 1:K)
      theta_hat[j,k,] <- count[j,k,] / sum(count[j,k,]);

  p <- array(0,c(I,K));
  for (i in 1:I)
    p[i,] <- pi_hat;
  for (n in 1:N)
    for (k in 1:K)
      p[ii[n],k] <- p[ii[n],k] * theta_hat[jj[n],k,y[n]];
  log_posterior <- 0.0;
  for (i in 1:I)
    log_posterior <- log_posterior + log(sum(p[i,]));
  if (epoch == 1)
    print(paste("epoch=",epoch," log posterior=", log_posterior));
  if (epoch > 1) {
    diff <- log_posterior - last_log_posterior;
    relative_diff <- abs(diff / last_log_posterior);
    print(paste("epoch=",epoch,
                " log posterior=", log_posterior,
                " relative_diff=",relative_diff));
    if (relative_diff < min_relative_diff) {
      print("FINISHED.");
      break;
    }
  }
  last_log_posterior <- log_posterior;
}


# VOTED PREVALENCE AS A SANITY CHECK; compare to estimates of pi
voted_prevalence <- rep(0,K);
for (k in 1:K)
  voted_prevalence[k] <- sum(y == k);
voted_prevalence <- voted_prevalence / sum(voted_prevalence);
print(paste("voted prevalence=",voted_prevalence));

pi_out <- array(0,dim=c(K,2),dimnames=list(NULL,c("category","prob")));
pos <- 1;
for (k in 1:K) {
  pi_out[pos,] <- c(k,pi_hat[k]);
  pos <- pos + 1;
}
write.table(pi_out,sep='\t',row.names=FALSE,file="pi_hat.tsv",quote=FALSE);

theta_out <- array(0,
                   dim=c(J*K*K,4),
                   dimnames=list(NULL,c("annotator","reference",
                                        "response","prob")));
pos <- 1;
for (j in 1:J) {
  for (ref in 1:K) {
    for (resp in 1:K) {
      theta_out[pos,] <- c(j,ref,resp,theta_hat[j,ref,resp]);
      pos <- pos + 1;
    }
  }
}
write.table(theta_out,
            sep='\t',
            row.names=FALSE,
            file="theta_hat.tsv",quote=FALSE);

z_out <- array(0,dim=c(I*K,3),
               dimnames=list(NULL,c("item","category","prob")));
pos <- 1;
for (i in 1:I) {
  for (k in 1:K) {
    z_out[pos,] = c(i,k,E_z[i,k]);
    pos <- pos + 1;
  }
}
write.table(z_out,sep='\t',row.names=FALSE,file="z_hat.tsv",quote=FALSE);

