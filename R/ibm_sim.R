#' Simulate draws from a fitted inverse Burr model
#' 
#' This function allows you to simulate random draws from an
#' inverse Burr model fit using the `ibm()` function. It uses
#' `{furrr}` under the hood giving you the option to perform the simulation
#' with parallel processing.
#' 
#' @param model A model fit with the `ibm()` function.
#' @param its The number of random draws. The default is 1,000.
#' @param newdata An optional data frame with new covariate values to use for simulated values.
#' @param se Specify whether coefficient standard errors should be factored into the simulation. Default is `FALSE`.
#' @export
ibm_sim <- function(model, its = 1000, newdata = NULL, se = FALSE) {
  
  ## specify the data for simulations
  if(is.null(newdata)) {
    pdata <- model$model_data
  } else {
    newdata <- as.data.frame(newdata)
    dnames <- colnames(model$model_data)
    ndata <- matrix(1, nrow(newdata), length(dnames))
    colnames(ndata) <- dnames
    for(i in 1:length(dnames)) {
      if(dnames[i] %in% colnames(newdata)) {
        ndata[, i] <- 
          newdata[, colnames(newdata) == dnames[i]]
      }
    }
    pdata <- ndata
  }
  
  ## make a function to calculate conditional fitted parameters given data
  param_fit <- function(model, data = pdata, par, se) {
    npars <- 1:nrow(model$out)
    names(npars) <- model$out$param
    X <- data[, npars[names(npars) == par]]
    coefs <- model$out |>
      dplyr::filter(param == par) |>
      dplyr::pull(estimate)
    if(se) {
      ses <- model$out |>
        dplyr::filter(param == par) |>
        dplyr::pull(std.error)
      coefs <- rnorm(length(coefs), coefs, ses)
    }
    exp(X %*% coefs)
  }
  
  ## iteratively simulate new outcomes
  furrr::future_map_dfr(
    .x = 1:(its * nrow(pdata)),
    .f = ~ newdata |>
      dplyr::mutate(
        sim = .x,
        pred = actuar::rinvburr(
          n = nrow(pdata),
          scale = param_fit(model, par = "mu", se = se),
          shape1 = param_fit(model, par = "alpha", se = se),
          shape2 = param_fit(model, par = "theta", se = se)
        )
      ),
    .options = furrr::furrr_options(seed = T)
  )
}
