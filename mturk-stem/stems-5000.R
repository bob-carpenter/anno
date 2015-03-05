stems.raw <- scan("data/mturk-stem/stems-5000.tsv")
K <- length(stems.raw)/3
stems.mat <- matrix(stems.raw,nrow=K,ncol=3,byrow=TRUE)
jj <- stems.mat[,1]
ii <- stems.mat[,2]
xx <- stems.mat[,3]
I <- max(ii)
J <- max(jj)
