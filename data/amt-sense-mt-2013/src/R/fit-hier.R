# run this via RScript
# Rscript fit-hier.R <input - tsv> <output dir> <label> <iterations> <chains>

options(echo=TRUE) # if you want see commands in output file
args <- commandArgs(trailingOnly = TRUE)
print(args)

# first need to install rstan;  see install wiki online:
#   http://mc-stan.org/r-quickstart.html
library(rstan);

# DATA:  tab separated values, 3 columns
# question rater judgment
# 1 1 1
# 1 2 1
# ...


dataDir <- path.expand("~/anno/data/amt-sense-mt-2013/munged");
#dataFile = file.path(dataDir,"time-n.tsv",fsep=.Platform$file.sep);
dataFile = file.path(dataDir,"board-n.tsv",fsep=.Platform$file.sep);
data <- read.table(dataFile,header=T,comment.char='#');

ii <- data[,1];    # item for labels
jj <- data[,2];    # annotator for labels
y <- data[,3];     # labels

I <- max(ii);      # number of items
J <- max(jj);      # number of annotators
K <- max(y);       # number of categories
N <- dim(data)[1]; # total number of labels

# HYPERPARAMETERS
alpha <- rep(1,K);              
print("alpha=");
print(alpha);

gamma <- matrix(0.5,K,K);
for (k in 1:K)
  gamma[k,k] = 3 * K;
print("gamma=");
print(gamma);

# INITS
piInit <- rep(0,K);
for (n in 1:N)
  piInit[y[n]] <- piInit[y[n]] + 1;
piInit <- piInit / sum(piInit)
print("piInit=");
print(piInit);

accuracyInit = 0.8;

betameanInit = matrix((1 - accuracyInit) / (K - 1), nrow=K, ncol=K);
for (k in 1:K)  
  betameanInit[k,k] = accuracyInit;

print("betameanInit=");
print(betameanInit);

betacountInit = array(4*K, dim=K);

print("betacountInit=");
print(betacountInit);

thetaInit <- array((1-accuracyInit)/(K-1),c(J,K,K));
for (j in 1:J)
  for (k in 1:K)
    thetaInit[j,k,k] = accuracyInit;


init_fun = function() { 
  return(list(pi=piInit,
              theta=thetaInit,
              betacount=betacountInit,
              betamean=betameanInit));
}

print(Sys.time());
print("fit");

modelDir <- path.expand("~/anno/model/dawid-skene");
modelFile = file.path(modelDir,"dawid-skene-hier.stan",fsep=.Platform$file.sep);

data_list <- list(I=I, J=J, K=K, N=N, ii=ii, jj=jj, y=y, alpha=alpha, gamma=gamma);
fit <- stan(file=modelFile,
           init=init_fun,
           data=data_list,
           iter=500, chains=4,
           refresh=1);


print(Sys.time());
print("extract")

fit_ss <- extract(fit);
traceplot(fit,'beta[8,3]');

print(Sys.time());
print("save");

#save(fit_ss,data,ii,I,jj,J,N,y,K,file="timen_ds_hier_i500_c4_samples.RData");
save(fit_ss,data,ii,I,jj,J,N,y,K,file="boardn_ds_hier_i500_c4_samples.RData");


print(Sys.time());
print("done");
