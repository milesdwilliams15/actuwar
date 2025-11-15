
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
