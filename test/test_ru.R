
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
  its = 2000,
  newdata = data.frame(
    pop = mean(wars$pop),
    maj = 0:1,
    dem = mean(wars$dem)
  ),
  se = T
) -> sim_data

library(ggplot2)
llplot(
  sim_data,
  pred,
  by = maj
) +
  scale_color_gradient(
    low = "red",
    high = "blue",
    guide = "legend",
    breaks = 0:1
  ) +
  labs(
    color = "Major Power"
  ) +
  theme(
    legend.position = c(.2, .25),
    legend.title = element_text(size = 8)
  )

sim_data |>
  group_by(maj) |>
  boot_p(pred, thresh = 1e06) |>
  ggplot() +
  aes(as.factor(maj), mean, ymin = lower, ymax = upper) +
  geom_pointrange()

