#' Make a log-log plot of the empirical Pr(X > x) given x
#' 
#' This function allows you to plot a 
#' log-log plot of Pr(X > x) given x.
#' 
#' @param mu The scale parameter for an inverse Burr model.
#' @param alpha The first shape parameter for an inverse Burr model.
#' @param theta The second shape parameter for an inverse Burr model.
#' @param xmin Default is 0. The minimum level of x to show in the plot.
#' @param xmax Default is 1000. The maximum level of x to show in the plot.
#' @param len Default is 1000. The level of granularity for x.
#' @param add Are you adding a new inverse Burr model to an existing plot? Default is `FALSE`.
#' @param legend Default is `NULL`. Do you want to include a legend if adding additional plots? This lets you select the category name for a particular model.
#' @param legend_title Default is `NULL`. Do you want to provide a custom name for your legend plot?
#' @export
llplot <- function(data, x) {
  if(missing(data)) {
    data <- tibble::tibble(x = x) |>
      tidyr::drop_na() 
  } else {
    data <- data |>
      dplyr::transmute(
        x = !!equo(x)
      ) |>
      tidyr::drop_na() 
  }
  
  data$p <- 0
  for(i in 1:nrow(data)) {
    data$p[i] <- mean(data$x > data$x[i])
  }
  
  ggplot2::ggplot(data) +
    ggplot2::aes(x = x, y = p) +
    ggplot2::geom_point() +
    ggplot2::scale_x_log10() +
    ggplot2::scale_y_log10() +
    ggplot2::labs(
      title = "Log-log plot of Pr(X > x) by x",
      x = NULL,
      y = NULL
    )
}