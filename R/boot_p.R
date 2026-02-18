#' Simulate and do inference for Pr(X > x) at different thresholds
#' 
#' This function allows you to estimate Pr(X > x) for some variable, potentially grouped by any number of factors, and 
#' perform bootstrapping for statistical inference.
#' 
#' @param data A data object. Can be either grouped or un-grouped.
#' @param var The variable for which Pr(X > x) will be computed.
#' @param thresh A numerical threshold for which Pr(X > x) is computed. If missing, an error will be returned.
#' @param its The number of bootstrap iterations. The default is 1,000.
#' @param ci A value between 0 and 1 indicating the quantile confidence interval level to be returned. 0.95 is the default.
#' @returns A data frame with the following values:
#' \describe{
#'   \item{estimate}{The estimated Pr(X > x).}
#'   \item{lower}{The lower bound of the bootstrapped confidence interval.}
#'   \item{upper}{The upper bound of the bootstrapped confidence interval.}
#' }
#' 
#' @examples 
#' library(dplyr)
#' wars |>
#'   group_by(post1950) |>
#'   boot_p(fat, thresh = 1e06, ci = .84)
#' 
#' @export
boot_p <- function(data, var, thresh, its = 1000, ci = 0.95) {
  
  ## return error if val is missing
  if(missing(thresh)) {
    stop("Option 'thresh' is missing. You should specify a threshold value for which to compute Pr(X > x).")
  }
  
  ## get the observed Pr(X > x)
  data |>
    dplyr::mutate(
      x = !!dplyr::enquo(var)
    ) -> data
  data |>
    dplyr::summarize(
      estimate = mean(.data$x > thresh)
    ) -> obs_out
  
  ## bootstrap the data and get Pr(X > x)
  1:its |>
    furrr::future_map_dfr(
      ~ data |>
        dplyr::sample_n(nrow(data), T) |>
        dplyr::summarize(
          prob = mean(.data$x > thresh),
          .groups = "keep"
        ),
      .options = furrr::furrr_options(seed = T)
    ) -> boot_out
  
  ## return a summary of bootstrapped Pr(X > x)
  boot_out |>
    dplyr::summarize(
      lower = stats::quantile(.data$prob, 1 - (ci + (1 - ci) / 2)),
      upper = stats::quantile(.data$prob, ci + (1 - ci) / 2),
    ) -> boot_out
  
  if(nrow(obs_out) == 1) {
    dplyr::bind_cols(obs_out, boot_out)
  } else {
    suppressMessages(dplyr::left_join(obs_out, boot_out))
  }
}
