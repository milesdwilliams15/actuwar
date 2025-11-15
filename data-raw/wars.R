## code to prepare `wars` dataset goes here

## Setup ----
library(tidyverse)
library(peacesciencer)

## Data on war size ----
# Use peacesciencer to construct a conflict-series
# dataset of international wars from 1816-2007.

# A custom function to populate with COW war data
add_cow_wars_new <- function(data) {
  the_data <- cow_war_inter %>% group_by(.data$ccode1, 
                                         .data$ccode2, .data$year) %>% arrange(.data$ccode1, 
                                                                               .data$ccode2, .data$year) %>% mutate(duplicated = ifelse(n() > 
                                                                                                                                          1, 1, 0), sddd = sd(.data$cowinteronset)) %>% 
    mutate(removeme = case_when(.data$duplicated == 
                                  1 & .data$sddd > 0 & .data$cowinteronset == 
                                  0 ~ 1, TRUE ~ 0)) %>% filter(.data$removeme == 
                                                                 0) %>% group_by(.data$ccode1, .data$ccode2, .data$year) %>% 
    mutate_at(vars(contains("death")), ~ifelse(. < 
                                                 0, NA, .)) %>% rowwise() %>% mutate(deaths = .data$batdeath1 + 
                                                                                       .data$batdeath2) %>% mutate(deaths = case_when(is.na(.data$deaths) & 
                                                                                                                                        is.na(.data$batdeath1) ~ .data$batdeath2, is.na(.data$deaths) & 
                                                                                                                                        is.na(.data$batdeath2) ~ .data$batdeath1, TRUE ~ 
                                                                                                                                        .data$deaths)) %>% group_by(.data$ccode1, .data$ccode2, 
                                                                                                                                                                    .data$year) %>% mutate(duplicated = ifelse(n() > 
                                                                                                                                                                                                                 1, 1, 0)) %>% arrange(-.data$deaths) %>% slice(1) %>% 
    ungroup() %>% select(.data$warnum:.data$resume)
  data <- the_data %>% left_join(data, .) %>% mutate_at(vars("cowinteronset", 
                                                             "cowinterongoing"), ~ifelse(is.na(.) & between(.data$year, 
                                                                                                            1816, 2007), 0, .))
  return(data)
}

## Start with a directed-country-pairs panel
create_dyadyears(
  directed = T,
  subset_years = 1816:2007
) |> ## then populate with variables
  add_cow_wars_new() |>
  filter(cowinteronset == 1) |>
  add_democracy() |>
  add_cow_majors() |>
  add_nmc() -> dt

## Collapse it to the year level
dt |>
  transmute(
    ccode1, warnum, year,
    fat = batdeath1,
    pop = tpop1,
    dem = polity21,
    mil = milper1,
    maj = cowmaj1
  ) |>
  distinct() |>
  group_by(ccode1, warnum) |>
  filter(year == min(year)) |>
  group_by(warnum) |>
  summarize(
    year = min(year),
    n = n(),
    across(fat:maj, ~ sum(.x, na.rm = T)),
    dem = dem / n,
    maj = (maj > 0) + 0
  ) -> ydt

## Some final touches
ydt |>
  mutate(
    pop = log(pop),
    mil = log(mil),
    post1950 = ifelse(year > 1950, "post-1950", "pre-1950")
  ) -> wars

## Save the data as .rda file ----
usethis::use_data(wars, overwrite = TRUE)
