#' Simulate Pr(X > x) for an inverse Burr model outcome
#' 
#' This function allows you to simulate random draws from an
#' inverse Burr model fit using the `ibm()` function.
#' 
#' @param data A data object. Can be either grouped or un-grouped.
#' @param var The variable for which Pr(X > x) will be computed.
#' @param thresh A numerical threshold for which Pr(X > x) is computed. If missing, an error will be returned.
#' @param its The number bootstrap iterations. The default is 1,000.
#' @param ci A value between 0 and 1 indicating the quantile confidence interval level to be returned. 0.95 is the default.
#' @export
boot_p <- function(data, var, thresh, its = 1000, ci = 0.95) {
  
  ## return error if val is missing
  if(missing(thresh)) {
    stop("Option 'thresh' is missing. You should specify a threshold value for which to compute Pr(X > x).")
  }
  
  ## bootstrap the data and get Pr(X > x)
  data |>
    dplyr::mutate(
      x = !!dplyr::enquo(var)
    ) -> data
  1:its |>
    furrr::future_map_dfr(
      ~ data |>
        dplyr::sample_n(nrow(data), T) |>
        dplyr::summarize(
          prob = mean(x > thresh),
          .groups = "keep"
        ),
      .options = furrr::furrr_options(seed = T)
    ) -> boot_out
  
  ## return a summary of bootstrapped Pr(X > x)
  boot_out |>
    dplyr::summarize(
      mean = mean(prob),
      median = median(prob),
      se = sd(prob),
      lower = quantile(prob, 1 - (ci + (1 - ci) / 2)),
      upper = quantile(prob, ci + (1 - ci) / 2),
      sims = its
    )
}
