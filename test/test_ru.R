
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
  data = wars,
  its = 200
) -> model_fit

ibm_sim(
  model_fit,
  newdata = data.frame(
    pop = mean(wars$pop),
    post1950 = mean(wars$maj),
    dem = c(-5, 0, 5)
  ),
  se = T
) -> sim_data

llplot(
  sim_data,
  pred,
  by = dem
) +
  labs(
    color = "Avg. Polity 2"
  ) +
  scale_color_gradient2(
    low = "red",
    mid = "gray",
    high = "blue",
    guide = "legend",
    breaks = c(-5, 0, 5)
  ) +
  theme(
    legend.position = c(.2, .25),
    legend.title = element_text(size = 8)
  )

sim_data |>
  group_by(dem) |>
  boot_p(pred, thresh = 16e06, ci = 0.834) |>
  ggplot() +
  aes(as.factor(dem), estimate, ymin = boot_lower, ymax = boot_upper) +
  geom_pointrange()

wars |>
  group_by(post1950) |>
  boot_p(fat, thresh = 1e06, ci = 0.834) |>
  ggplot() +
  aes(post1950, estimate, ymin = boot_lower, ymax = boot_upper) +
  geom_pointrange()
