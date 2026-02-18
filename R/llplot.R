#' Make a log-log plot of the empirical Pr(X > x) given x
#' 
#' This function allows you to plot a 
#' log-log plot of Pr(X > x) given x.
#' 
#' @param data A data object for the variable you want to plot.
#' @param x The variable for which you you want to plot Pr(X > x).
#' @param by An optional grouping variable. Should be a character or factor.
#' @param show_fit If `TRUE` the plot will include an inverse Burr fit for the data. Default is `FALSE`.
#'
#' @returns A ggplot object showing the relationship between a variable and its empirical Pr(X > x), both on a log-10 scale.
#'
#' @examples llplot(wars, fat, show_fit = TRUE)
#' @import ggplot2
#' @export
llplot <- function(data, x, by, show_fit = FALSE) {
  if(missing(data)) {
    stop("A data object is missing. Did you forget to include a dataset?")
  } 
  if(missing(by)) {
    x <- dplyr::enquo(x)
    data |>
      dplyr::transmute(
        by = 0,
        x = !!x
      ) -> ndata
  } else {
    by <- dplyr::enquo(by)
    x  <- dplyr::enquo(x)
    data |>
      dplyr::transmute(
        by = !!by,
        x = !!x,
      ) -> ndata
  }
  ndata |>
    tidyr::drop_na() |>
    dplyr::group_by(by) |>
    dplyr::mutate(
      p = rank(-.data$x) / max(rank(-.data$x))
    ) |>
    dplyr::group_split(by) |>
    purrr::map(~ {
      fit <- suppressMessages(ibm(x, data = .x, its = 1, verbose = F))
      
      .x |>
        dplyr::mutate(
          fit = actuar::pinvburr(
            q = x,
            scale = exp(fit$summary$estimate[1]),
            shape1 = exp(fit$summary$estimate[2]),
            shape2 = exp(fit$summary$estimate[3]),
            lower.tail = F
          )
        )
    }) |>
    dplyr::bind_rows() -> ndata
  
  ggplot2::ggplot(ndata) +
    ggplot2::aes(x = .data$x, y = .data$p, color = .data$by) +
    ggplot2::geom_point(
      show.legend = !missing(by),
      alpha = .4
    ) +
    ggplot2::scale_x_log10() +
    ggplot2::scale_y_log10() +
    ggplot2::labs(
      x = dplyr::enquo(x),
      y = "Pr(X > x)"
    ) -> the_plot
  
  if(show_fit) {
    the_plot +
      ggplot2::geom_line(
        data = ndata,
        ggplot2::aes(x = .data$x, y = .data$fit, color = .data$by),
        show.legend = !missing(by),
        linewidth = .75
      ) -> the_plot
  }
  
  the_plot
}
