/*
 * Dawid and Skene. 1979.
 *
 * Extended with fixed priors.
 *
 * Discrete parameters for category of items marginalized out.
 *
 *  p(y | pi, theta)
 *  = PROD_i SUM_k p(k | pi) 
 *                 * PROD_{n: ii[n]=i} p(y[n] | theta[jj[n], k])
 * 
 *  log p(y | pi, theta)
 *  = SUM_i log SUM_k p(k | pi) 
 *                    * PROD_{n: ii[n]=i} p(y[n] | theta[jj[n], k])
 *
 *  = SUM_i log SUM_k exp(log ( p(k | pi) 
 *                              * PROD_{n: ii[n]=i} p(y[n] | theta[jj[n], k])))
 *
 *  = SUM_i log SUM_k exp(log p(k | pi)
 *                        + SUM_{n: ii[n]=i} log p(y[n] | theta[jj[n], k]))
 *
 * = SUM_i LOG_SUM_EXP_k log p(k | pi)
 *                        + SUM_{n: ii[n]=i} log p(y[n] | theta[jj[n], k])
 */

data {
  int<lower=1> I;              // number of items
  int<lower=1> J;              // number of coders
  int<lower=2> K;              // number of categories
  int<lower=1> N;              // number of observations
  int<lower=1,upper=I> ii[N];  // item for observation n
  int<lower=1,upper=J> jj[N];  // coder for observation n
  int<lower=1,upper=K> y[N];   // label for observation n
  vector<lower=0>[K] alpha;    // prior for prevalence (positive)
  vector<lower=0>[K] beta[K];  // prior for coder responses (positive)
}
parameters {
  simplex[K] pi;               // prevalence of categories
  simplex[K] theta[J,K];       // response of anotator j to category k
}
model {
  real cat_log[I,K];  // vector of log probs (up to const) for item i

  pi ~ dirichlet(alpha);
  for (j in 1:J)
    for (k in 1:K)
      theta[j,k] ~ dirichlet(beta[k]);

  for (i in 1:I)
    for (k in 1:K)
      cat_log[i,k] <- log(pi[k]);  // efficiency: compute log(pi[k]) once
  for (n in 1:N)
    for (k in 1:K)
      cat_log[ii[n],k] <- cat_log[ii[n],k] + log(theta[jj[n],k,y[n]]);
  for (i in 1:I)
    lp__ <- lp__ + log_sum_exp(cat_log[i]);
}
generated quantities {
  vector[K] expected_Z[I];
  for (i in 1:I)
    expected_Z[i] <- pi;
  for (n in 1:N)
    for (k in 1:K)
      expected_Z[ii[n],k] <- expected_Z[ii[n],k] * theta[jj[n],k,y[n]];
  for (i in 1:I)
    expected_Z[i] <- expected_Z[i] / sum(expected_Z[i]);
}













