#' Simulate draws from a fitted inverse Burr model
#' 
#' This function allows you to simulate random draws from an
#' inverse Burr model fit using the `ibm()` function.
#' 
#' @param model A model fit with the `ibm()` function.
#' @param its The number of random draws. The default is 1,000.
#' @param newdata An optional data frame with new covariate values to use for simulated values.
#' @export
ibm_sim <- function(model, its = 1000, newdata = NULL) {
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
  param_fit <- function(model, data = pdata, par = "mu") {
    npars <- 1:nrow(model$out)
    names(npars) <- model$out$param
    exp(data[
      , npars[names(npars) == par]
    ] %*% (model$out |>
             filter(param == par) |>
             pull(estimate)))
  }
  map_dfr(
    .x = 1:(its * nrow(pdata)),
    .f = ~ newdata |>
      mutate(
        sim = .x,
        pred = actuar::rinvburr(
          n = nrow(pdata),
          scale = param_fit(model, par = "mu"),
          shape1 = param_fit(model, par = "alpha"),
          shape2 = param_fit(model, par = "theta")
        )
      )
  )
}