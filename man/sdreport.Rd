% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/sdreport.R
\name{sdreport}
\alias{sdreport}
\title{General sdreport function.}
\usage{
sdreport(obj, par.fixed = NULL, hessian.fixed = NULL,
  getJointPrecision = FALSE, bias.correct = FALSE,
  bias.correct.control = list(sd = FALSE, split = NULL, nsplit = NULL),
  ignore.parm.uncertainty = FALSE, getReportCovariance = TRUE,
  skip.delta.method = FALSE)
}
\arguments{
\item{obj}{Object returned by \code{MakeADFun}}

\item{par.fixed}{Optional. Parameter estimate (will be known to \code{obj} when an optimization has been carried out).}

\item{hessian.fixed}{Optional. Hessian wrt. parameters (will be calculated from \code{obj} if missing).}

\item{getJointPrecision}{Optional. Return full joint precision matrix of random effects and parameters?}

\item{bias.correct}{logical indicating if bias correction should be applied}

\item{bias.correct.control}{a \code{list} of bias correction options; currently \code{sd}, \code{split} and \code{nsplit} are used - see details.}

\item{ignore.parm.uncertainty}{Optional. Ignore estimation variance of parameters?}

\item{getReportCovariance}{Get full covariance matrix of ADREPORTed variables?}

\item{skip.delta.method}{Skip the delta method? (\code{FALSE} by default)}
}
\value{
Object of class \code{sdreport}
}
\description{
After optimization of an AD model, \code{sdreport} is used to
calculate standard deviations of all model parameters, including
non linear functions of random effects and parameters specified
through the ADREPORT() macro from the user template.
}
\details{
First, the Hessian wrt. the parameter vector (\eqn{\theta}) is
calculated.  The parameter covariance matrix is approximated by
\deqn{V(\hat\theta)=-\nabla^2 l(\hat\theta)^{-1}} where \eqn{l}
denotes the log likelihood function (i.e. \code{-obj$fn}).  If
\code{ignore.parm.uncertainty=TRUE} then the Hessian calculation
is omitted and a zero-matrix is used in place of
\eqn{V(\hat\theta)}.

For non-random effect models the standard delta-method is used to
calculate the covariance matrix of transformed parameters. Let
\eqn{\phi(\theta)} denote some non-linear function of
\eqn{\theta}. Then \deqn{V(\phi(\hat\theta))\approx \nabla\phi
V(\hat\theta) \nabla\phi'}

The covariance matrix of reported variables
\eqn{V(\phi(\hat\theta))} is returned by default. This can cause
high memory usage if many variables are ADREPORTed. Use
\code{getReportCovariance=FALSE} to only return standard errors.
In case standard deviations are not required one can completely skip
the delta method using \code{skip.delta.method=TRUE}.

For random effect models a generalized delta-method is used. First
the joint covariance of random effect and parameter estimation error is approximated
by
\deqn{V \left( \begin{array}{cc} \hat u - u \cr \hat\theta - \theta \end{array} \right) \approx
\left( \begin{array}{cc} H_{uu}^{-1} & 0 \cr 0 & 0 \end{array} \right) +
J V(\hat\theta) J'
}
where \eqn{H_{uu}} denotes random effect block of the full joint
Hessian of \code{obj$env$f} and \eqn{J} denotes the Jacobian of
\eqn{\left( \begin{array}{cc}\hat u(\theta) \cr \theta \end{array} \right)} wrt. \eqn{\theta}.
Here, the first term represents the expected conditional variance
of the estimation error given the data and the second term represents the variance
of the conditional mean of the estimation error given the data.

Now the delta method can be applied on a general non-linear
function \eqn{\phi(u,\theta)} of random effects \eqn{u} and
parameters \eqn{\theta}:
\deqn{V\left(\phi(\hat u,\hat\theta) - \phi(u,\theta) \right)\approx \nabla\phi V \left( \begin{array}{cc}
\hat u - u \cr \hat\theta - \theta \end{array} \right) \nabla\phi'}

The full joint covariance is not returned by default, because it
may require large amounts of memory.  It may be obtained by
specifying \code{getJointPrecision=TRUE}, in which case \eqn{V
\left( \begin{array}{cc} \hat u - u \cr \hat\theta - \theta \end{array} \right) ^{-1} } will be part of the
output. This matrix must be manually inverted using
\code{solve(jointPrecision)} in order to get the joint covariance
matrix. Note, that the parameter order will follow the original
order (i.e. \code{obj$env$par}).

Using \eqn{\phi(\hat u,\theta)} as estimator of
\eqn{\phi(u,\theta)} may result in substantial bias. This may be
the case if either \eqn{\phi} is non-linear or if the distribution
of \eqn{u} given \eqn{x} (data) is sufficiently non-symmetric.  A
generic correction is enabled with \code{bias.correct=TRUE}. It is
based on the identity
\deqn{E_{\theta}[\phi(u,\theta)|x] =
\partial_\varepsilon\left(\log \int \exp(-f(u,\theta) +
\varepsilon \phi(u,\theta))\:du\right)_{|\varepsilon=0}}
stating that the conditional expectation can be written as a
marginal likelihood gradient wrt. a nuisance parameter
\eqn{\varepsilon}.
The marginal likelihood is replaced by its Laplace approximation.

If \code{bias.correct.control$sd=TRUE} the variance of the
estimator is calculated using
\deqn{V_{\theta}[\phi(u,\theta)|x] =
\partial_\varepsilon^2\left(\log \int \exp(-f(u,\theta) +
\varepsilon \phi(u,\theta))\:du\right)_{|\varepsilon=0}}
A further correction is added to this variance to account for the
effect of replacing \eqn{\theta} by the MLE \eqn{\hat\theta}
(unless \code{ignore.parm.uncertainty=TRUE}).

Bias correction can be be performed in chunks in order to reduce
memory usage or in order to only bias correct a subset of
variables. First option is to pass a list of indices as
\code{bias.correct.control$split}. E.g. a list
\code{list(1:2,3:4)} calculates the first four ADREPORTed
variables in two chunks.
The internal function \code{obj$env$ADreportIndex()}
gives an overview of the possible indices of ADREPORTed variables.

Second option is to pass the number of
chunks as \code{bias.correct.control$nsplit} in which case all
ADREPORTed variables are bias corrected in the specified number of
chunks.
Also note that \code{skip.delta.method} may be necessary when bias
correcting a large number of variables.
}
\examples{
\dontrun{
runExample("linreg_parallel", thisR = TRUE) ## Non-random effect example
sdreport(obj) }

runExample("simple", thisR = TRUE)          ## Random effect example
rep <- sdreport(obj)
summary(rep, "random")                      ## Only random effects
summary(rep, "fixed", p.value = TRUE)       ## Only non-random effects
summary(rep, "report")                      ## Only report

## Bias correction
rep <- sdreport(obj, bias.correct = TRUE)
summary(rep, "report")                      ## Include bias correction
}
\seealso{
\code{\link{summary.sdreport}}, \code{\link{print.sdreport}}, \code{\link{as.list.sdreport}}
}
