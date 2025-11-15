
# TEST RUN ----------------------------------------------------------------

## Setup ----
# devtools::install_github("milesdwilliams15/actuwar")
library(actuwar)

## fit an inverse Burr model ----

## use `wars` data object with {actuwar}

ibm(
  outcome = fat,
  mu = ~ pop + mil + maj + dem + post1950,
  alpha = ~ pop + mil + maj + dem + post1950,
  theta = ~ pop + mil + maj + dem + post1950,
  data = wars,
  its = 2000
) -> ft

## can I run in parallel?
library(furrr)
cores <- availableCores() - 1
plan(multisession, workers = cores)
ibm(
  outcome = fat,
  mu = ~ pop + mil + maj + dem + post1950,
  alpha = ~ pop + mil + maj + dem + post1950,
  theta = ~ pop + mil + maj + dem + post1950,
  data = wars,
  its = 2000
) -> ft

## plot empirical log-log ----

llplot(wars, fat) +
  labs(
    x = "Battle Deaths"
  )


## simulate ----

library(furrr)
cores <- availableCores() - 1
plan(multisession, workers = cores)

## estimate the model
ibm(
  outcome = fat,
  mu = ~ log(pop) + maj + dem,
  alpha = ~ log(pop) + maj + dem,
  theta = ~ log(pop) + maj + dem,
  data = wars
) -> model_fit

ibm_sim(
  model_fit,
  its = 1000,
  newdata = data.frame(
    pop = mean(wars$pop),
    maj = mean(wars$maj),
    dem = c(-5, 0, 5)
  )
) -> sim_data

library(ggplot2)
llplot(
  sim_data,
  pred,
  by = dem
) +
  scale_color_gradient2(
    low = "red",
    mid = "gray",
    high = "blue",
    guide = "legend",
    breaks = c(-5, 0, 5)
  ) +
  labs(
    color = "Avg. Polity 2"
  ) +
  theme(
    legend.position = c(.2, .25),
    legend.title = element_text(size = 8)
  )
