#' Estimate an Inverse Burr Regression Model
#'
#' Fits an inverse Burr regression model where the scale (\code{mu}) and
#' two shape parameters (\code{alpha}, \code{theta}) may be modeled as
#' functions of covariates via log-link parameterization.
#'
#' @param outcome The outcome variable to be modeled. Can be supplied
#'   unquoted if \code{data} is provided, or as a numeric vector.
#' @param mu A right-hand-side formula specifying the linear predictor
#'   for the scale parameter. Default is \code{~ 1}.
#' @param alpha A right-hand-side formula specifying the linear predictor
#'   for the first shape parameter. Default is \code{~ 1}.
#' @param theta A right-hand-side formula specifying the linear predictor
#'   for the second shape parameter. Default is \code{~ 1}.
#' @param data A data frame containing the outcome and covariates.
#' @param its Number of bootstrap iterations for inference. Default is 2000.
#' @param verbose Logical. If \code{TRUE}, progress messages are shown.
#'
#' @returns A list with the following components:
#' \describe{
#'   \item{summary}{A tibble with parameter estimates and inference:
#'     \code{param}, \code{term}, \code{estimate},
#'     \code{std.error}, \code{statistic}, \code{p.value}.}
#'   \item{boot_values}{A tibble containing bootstrap coefficient
#'     estimates by iteration.}
#'   \item{model_matrix}{The combined model matrix used for estimation.}
#'   \item{logLik}{The maximized log-likelihood value.}
#'   \item{convergence}{Logical indicating whether optimization converged.}
#' }
#'
#' @examples
#' fit <- ibm(fat, ~ pre1950 + dem, ~ pre1950 + dem, ~ pre1950 + dem, wars)
#' fit$summary
#'
#' @export
ibm <- function(
    outcome,
    mu = ~ 1,
    alpha = ~ 1,
    theta = ~ 1,
    data = NULL,
    its = 2000,
    verbose = TRUE
) {
  
  ## --------------------------
  ## Input checks
  ## --------------------------
  
  if (!is.numeric(its) || its <= 0) {
    stop("`its` must be a positive integer.")
  }
  
  if (!is.null(data)) {
    y <- dplyr::pull(data, !!rlang::enquo(outcome))
  } else {
    y <- outcome
  }
  
  if (!is.numeric(y)) {
    stop("Outcome must be numeric.")
  }
  
  if (anyNA(y)) {
    stop("Missing values are not allowed.")
  }
  
  if (any(y <= 0)) {
    stop("Outcome must be strictly positive for the inverse Burr distribution.")
  }
  
  ## --------------------------
  ## Model matrices
  ## --------------------------
  
  if (is.null(data) &&
      (!identical(mu, ~1) ||
       !identical(alpha, ~1) ||
       !identical(theta, ~1))) {
    stop("If formulas include covariates, `data` must be supplied.")
  }
  
  x1 <- stats::model.matrix(mu, data)
  x2 <- stats::model.matrix(alpha, data)
  x3 <- stats::model.matrix(theta, data)
  
  model_matrix <- cbind(x1, x2, x3)
  
  p1 <- ncol(x1)
  p2 <- ncol(x2)
  p3 <- ncol(x3)
  p_total <- p1 + p2 + p3
  
  ## --------------------------
  ## Likelihood
  ## --------------------------
  
  inbur_lik <- function(pars, x1, x2, x3, y) {
    
    b1 <- pars[1:p1]
    b2 <- pars[(p1 + 1):(p1 + p2)]
    b3 <- pars[(p1 + p2 + 1):(p_total)]
    
    mu_val    <- exp(x1 %*% b1)
    alpha_val <- exp(x2 %*% b2)
    theta_val <- exp(x3 %*% b3)
    
    dens <- actuar::dinvburr(
      y,
      shape1 = alpha_val,
      shape2 = theta_val,
      scale  = mu_val
    )
    
    if (any(dens <= 0) || any(!is.finite(dens))) {
      return(Inf)
    }
    
    -sum(log(dens))
  }
  
  ## --------------------------
  ## Estimation
  ## --------------------------
  
  if (verbose) message("Fitting model...")
  
  opt_out <- stats::optim(
    par = rep(0, p_total),
    fn  = inbur_lik,
    x1 = x1,
    x2 = x2,
    x3 = x3,
    y  = y,
    hessian = FALSE
  )
  
  converged <- opt_out$convergence != 0
  
  if (!converged) {
    warning("Optimization may not have converged.")
  }
  
  ## --------------------------
  ## Bootstrap
  ## --------------------------
  
  if (verbose) message("Bootstrapping ", its, " iterations...")
  
  boot_list <- furrr::future_map(
    seq_len(its),
    function(i) {
      
      idx <- sample.int(length(y), length(y), replace = TRUE)
      
      res <- try(
        stats::optim(
          par = opt_out$par,
          fn  = inbur_lik,
          x1 = x1[idx, , drop = FALSE],
          x2 = x2[idx, , drop = FALSE],
          x3 = x3[idx, , drop = FALSE],
          y  = y[idx],
          hessian = FALSE
        ),
        silent = TRUE
      )
      
      if (inherits(res, "try-error")) {
        return(rep(NA_real_, p_total))
      }
      
      res$par
    },
    .options = furrr::furrr_options(seed = TRUE)
  )
  
  boot_mat <- do.call(rbind, boot_list)
  
  boot_se <- apply(boot_mat, 2, stats::sd, na.rm = TRUE)
  
  ## --------------------------
  ## Summary construction
  ## --------------------------
  
  est <- opt_out$par
  z   <- est / boot_se
  p   <- 2 * stats::pnorm(-abs(z))
  
  param_labels <- c(
    rep("mu", p1),
    rep("alpha", p2),
    rep("theta", p3)
  )
  
  term_labels <- c(
    colnames(x1),
    colnames(x2),
    colnames(x3)
  )
  
  summary_tbl <- tibble::tibble(
    param = param_labels,
    term = term_labels,
    estimate = est,
    std.error = boot_se,
    statistic = z,
    p.value = round(p, 3)
  )
  
  boot_values <- tibble::tibble(
    iteration = rep(seq_len(its), each = p_total),
    param = rep(param_labels, times = its),
    term = rep(term_labels, times = its),
    estimate = as.vector(t(boot_mat))
  )
  
  if (verbose) message("Done.")
  
  ## --------------------------
  ## Return
  ## --------------------------
  
  list(
    summary = summary_tbl,
    boot_values = boot_values,
    model_matrix = model_matrix,
    logLik = -opt_out$value,
    convergence = converged
  )
}
