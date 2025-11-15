# Make odadata package logo

library(hexSticker)
library(UCSCXenaTools)
library(tidyverse)
library(actuwar)
p <-
  llplot(wars, fat, show_fit = T) +
  labs(
    x = NULL,
    y = NULL
  ) +
  theme_transparent() +
  theme(
    axis.ticks = element_blank(),
    axis.text = element_blank(),
    panel.grid.major = element_line(color = "gray")
  )

sticker(
  p,
  package = "actuwar",
  p_size = 24,
  p_fontface = "bold",
  s_x = 1,
  s_y = 1,
  s_width=1.5,
  s_height = 1.5,
  spotlight = T,
  p_x = 1,
  p_y = .5,
  l_x = 1,
  l_y = .5,
  l_width = 30,
  l_height = 5,
  p_color = "red3",
  h_fill = "white",
  h_color = "red3",
  url = "https://github.com/milesdwilliams15/actuwar",
  filename = "inst/logo.png"
)
