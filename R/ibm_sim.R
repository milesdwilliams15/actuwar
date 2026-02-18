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
#' @returns A data frame, either the original model matrix or the new data object supplied along with simulated predictions in a new column called `pred`. The returned data frame will have as many rows as simulation iterations times the number of unique covariate value combinations provided.
#' 
#' @examples
#' fit   <- ibm(fat, ~ post1950 + dem, ~ post1950 + dem, ~ post1950 + dem, wars)
#' preds <- ibm_sim(fit, newdata = data.frame(post1950 = "post-1950", dem = .5))
#' 
#' @export
ibm_sim <- function(model, its = 1000, newdata = NULL, se = FALSE) {
  
  ## specify the data for simulations
  newdata <- if(is.null(newdata)) as.data.frame(model$model_matrix) else as.data.frame(newdata)
  dnames  <- colnames(model$model_matrix)
  ndata   <- matrix(1, nrow(newdata), length(dnames))
  colnames(ndata) <- dnames
  for(i in 1:length(dnames)) {
    if(dnames[i] %in% colnames(newdata)) {
      ndata[, i] <- newdata[, colnames(newdata) == dnames[i]]
    }
  }
  pdata <- ndata
  
  ## make a function to calculate conditional fitted parameters given data
  param_fit <- function(model, data = pdata, par, se) {
    npars <- 1:nrow(model$summary)
    names(npars) <- model$summary$param
    X <- data[, npars[names(npars) == par]]
    if(se) {
      s_its <- sample(unique(model$boot_values$iteration), 1)
      coefs <- model$boot_values[model$boot_values$iteration == s_its & 
                                   model$boot_values$param == par, ]$estimate
    } else {
      coefs <- model$summary[model$summary$param == par, ]$estimate
    }
    exp(X %*% coefs)
  }
  
  ## iteratively simulate new outcomes
  res <- furrr::future_map_dfr(
    1:(its * nrow(pdata)), function(i) {
      out      <- as.data.frame(newdata)
      out$sim  <- i
      out$pred <- actuar::rinvburr(
        nrow(pdata),
        scale = param_fit(model, par = "mu", se = se),
        shape1 = param_fit(model, par = "alpha", se = se),
        shape2 = param_fit(model, par = "theta", se = se)
      ) 
      
      ## return output
      out
    },
    .options = furrr::furrr_options(seed = TRUE)
  )
  
  ## return the simulated output
  res
}
