# fit-hier.R uses stan model file: dawid-skene-hier.stan
# run from command line:
# Rscript fit-hier.R <input - tsv> <output dir> <label> <iterations> <chains>

args <- commandArgs(trailingOnly = TRUE);
inFile <- args[1];
sprintf("input file: %s",inFile);
outDir <- args[2];
sprintf("output dir: %s",outDir);
sLabel <- args[3];
sprintf("label: %s",sLabel);
iIterations <- as.integer(args[4]);
sprintf("interations: %d",iIterations);
iChains <- as.integer(args[5]);
sprintf("chains: %s",iChains);

runLabel <- sprintf("%s_%d_%d",sLabel,iIterations,iChains);

# first need to install rstan;  see install wiki online:
#   http://mc-stan.org/r-quickstart.html
library(rstan);

# DATA:  tab separated values, 3 columns
# question rater judgment
# 1 1 1
# 1 2 1
# ...

data <- read.table(inFile,header=T,comment.char='#');

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

gamma <- matrix(2,K,K);
for (k in 1:K)
  gamma[k,k] = 2 * K;

print("prior accuracy=", 2 * K / (2 * K + (K - 1) * 2));

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

data_list <- list(I=I, J=J, K=K, N=N, ii=ii, jj=jj, y=y, alpha=alpha, gamma=gamma);

fit <- stan(file="../../model/dawid-skene/dawid-skene-hier.stan",
           init=init_fun,
           data=data_list,
           iter=iIterations,
           chains=iChains,
           refresh=1);

print(Sys.time());
print("extract")

fit_ss <- extract(fit);

#save plots
plotFile <- file.path(outDir,
                      sprintf("%s_%d_%d_plots.pdf",sLabel,iIterations,iChains),
                      fsep=.Platform$file.sep);
pdf(file=plotFile);
plot(fit);
dev.off();

plotFile <- file.path(outDir,
                      sprintf("%s_%d_%d_trace_beta.pdf",sLabel,iIterations,iChains),
                      fsep=.Platform$file.sep);
pdf(file=plotFile);
traceplot(fit,par=c("beta"),inc_warmup=F,ncol=2,nrow=3);
dev.off();

print(Sys.time());
print("save");

rdataFile <- file.path(outDir,
                       sprintf("%s_%d_%d_stanfit.RData",sLabel,iIterations,iChains),
                       fsep=.Platform$file.sep);
save(fit,file=rdataFile);

csvFile <- file.path(outDir,
                       sprintf("%s_%d_%d_samples.csv",sLabel,iIterations,iChains),
                       fsep=.Platform$file.sep);
write.csv(fit_ss,file=csvFile,row.names=FALSE);

print(Sys.time());
print("done");
