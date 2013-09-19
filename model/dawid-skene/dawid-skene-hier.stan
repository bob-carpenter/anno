data {
  int<lower=2> K;              // number of categories
  int<lower=1> I;              // number of items
  int<lower=1> J;              // number of coders
  int<lower=1> N;              // number of observations
  int<lower=1,upper=J> jj[N];  // coder for observation n
  int<lower=1,upper=I> ii[N];  // item for observation n
  int<lower=1,upper=K> y[N];   // label for observation n
  vector<lower=0>[K] alpha;             // prior for prevalence (positive)
  vector<lower=0>[K] gamma[K];          // prior for accuracy hyperprior
}
parameters {
  simplex[K] pi;                // prevalence of categories
  simplex[K] theta[J,K];        // response of anotator j to category k
  vector[K]<lower=0> betacount; // count of response prior
  simplex[K] betamean[K];       // mean of response prior
}
transformed parameters {
  vector[K] beta[K];           // prior for coder responses (positive)

  beta <- betacount .* betamean;
}
model {
  real cat_log[I,K];  // vector of log probs (up to const) for item i

  pi ~ dirichlet(alpha);

  // need prior on betamean to control low counts
  for (k in 1:K)
    betamean[k] ~ dirichlet(gamma[k]);
  
  betacount ~ cauchy(0,5);

  for (j in 1:J)
    for (k in 1:K)
      theta[j,k] ~ dirichlet(beta[k]);

  for (k in 1:K)
      cat_log[1,k] <- log(pi[k]);
  for (i in 2:I)
    for (k in 1:K)
      cat_log[i,k] <- cat_log[1,k];
  for (n in 1:N)
    for (k in 1:K)
      cat_log[ii[n],k] <- cat_log[ii[n],k] + log(theta[jj[n],k,y[n]]);
  for (i in 1:I)
    lp__ <- lp__ + log_sum_exp(cat_log[i]);
}
