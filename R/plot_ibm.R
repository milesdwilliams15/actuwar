#' Plot the fit of an inverse Burr model
#' 
#' This function allows you to plot the fit of an inverse Burr model in a 
#' log-log plot. It accepts the output of an `ibm()` fitted model and 
#' a required `newdata` object to simulate what Pr(X > x) given x conditional
#' on values for model covariates. 
#' 
#' @param model An object generated via `ibm()`.
#' @param newdata A new dataset for plotting. It must have no more than 1 row of values for model covariates.
#' @param xmin Default is 0. The minimum level of x to show in the plot.
#' @param xmax Default is 1000. The maximum level of x to show in the plot.
#' @param len Default is 1000. The level of granularity for x.
#' @param add Are you adding a new inverse Burr model to an existing plot? Default is `FALSE`.
#' @param legend Default is `NULL`. Do you want to include a legend if adding additional plots? This lets you select the category name for a particular model.
#' @param legend_title Default is `NULL`. Do you want to provide a custom name for your legend plot?
#' @export
plot_ibm <- function(
    model, 
    newdata,
    xmin = 0,
    xmax = 1000,
    len = 1000,
    add = F,
    legend = NULL,
    legend_title = NULL
) {
  ## Get the three sets of parameters
  mus <- model$out |> 
    dplyr::filter(param == "mu") |> 
    dplyr::pull(estimate)
  alphas <- model$out|>
    dplyr::filter(param == "alpha") |>
    dplyr::pull(estimate)
  thetas <- model$out |>
    dplyr::filter(param == "theta") |>
    dplyr::pull(estimate)
  
  ## Get the names of covariates
  munames <- model$out |> 
    dplyr::filter(param == "mu") |> 
    dplyr::pull(term) 
  alphanames <- model$out|>
    dplyr::filter(param == "alpha") |>
    dplyr::pull(term)
  thetanames <- model$out |>
    dplyr::filter(param == "theta") |>
    dplyr::pull(term)
  
  ## Apply the names to the relevant parameters
  names(mus) <- munames
  names(alphas) <- alphanames
  names(thetas) <- thetanames
  
  ## Compute the parameter fits
  if(length(mus) == 1) {
    theMu <- exp(mus)
  } else {
    x1 <- cbind(1, newdata[, names(mus)[-1]])
    theMu <- exp(sum(x1 * mus))
  }
  
  if(length(alphas) == 1) {
    theAlpha <- exp(alphas)
  } else {
    x2 <- cbind(1, newdata[, names(alphas)[-1]])
    theAlpha <- exp(sum(x2 * alphas))
  }
  
  if(length(thetas) == 1) {
    theTheta <- exp(thetas)
  } else {
    x3 <- cbind(1, newdata[, names(thetas)[-1]])
    theTheta <- exp(sum(x3 * thetas))
  }
  
  ## Define ll_plot locally
  ll_plot <- function(
    mu, alpha, theta, 
    xmin = 0,
    xmax = 1000, 
    len = 1000,
    add = F,
    legend = NULL,
    legend_title = NULL
  ) {
    
    ## X values to be plotted
    x <- exp(seq(ifelse(xmin <= 0, 0, log(xmin)), log(xmax), len = len))
    
    ## The probability that X > x
    p <- actuar::pinvburr(x, alpha, theta, scale = mu, lower.tail = F)
    
    ## Create the plot
    # ... if the plot is a new plot
    if(!add) {
      ggplot2::ggplot() +
        ggplot2::aes(x, p) +
        ggplot2::geom_line(
          ggplot2::aes(
            color = legend
          ),
          size = 1
        ) +
        ggplot2::scale_x_log10(
          labels = scales::comma
        ) +
        ggplot2::scale_y_log10(
          n.breaks = 9,
          labels = scales::percent
        ) +
        ggplot2::labs( 
          x = "x",
          y = "Pr(X > x)",
          color = legend_title
        ) +
        ggplot2::theme(
          panel.grid.major = 
            ggplot2::element_line(
              color = "black",
              linetype = 4,
              size = .5
            )
        ) 
    } else {
      # ... if making an addition to the plot
      ggplot2::last_plot() +
        ggplot2::geom_line(
          ggplot2::aes(x, p, color = legend),
          size = 1
        ) 
    }
  }
  
  ## Plot cdf of the distribution
  ll_plot(
    theMu,
    theAlpha,
    theTheta,
    xmin = xmin,
    xmax = xmax,
    add = add,
    len = len,
    legend = legend,
    legend_title = legend_title
  )
}
