
#' A custom theme specifically for use with joyplots
#'
#' This theme has some special modifications that make joyplots look better, such as properly aligned y axis labels.
#'
#' @param font_size Overall font size. Default is 14.
#' @param font_family Default font family.
#' @param line_size Default line size.
#' @param grid Boolean indicating whether a background grid should be drawn (`TRUE`) or not (`FALSE`).
#' @return The theme.
#' @examples
#' # still to do
#' @export
theme_joy <- function(font_size = 14, font_family = "", line_size = .5, grid = TRUE) {
  half_line <- font_size / 2
  small_rel <- 0.857
  small_size <- small_rel * font_size
  color <- "grey90"

  if (grid)
  {
    panel.grid.major <- element_line(colour = color, size = line_size)
    axis.ticks       <- element_line(colour = color, size = line_size)
    axis.ticks.y     <- axis.ticks
  }
  else
  {
    panel.grid.major <- element_blank()
    axis.ticks       <- element_line(colour = "black", size = line_size)
    axis.ticks.y     <- element_blank()
  }

  theme_grey(base_size = font_size, base_family = font_family) %+replace%
    theme(
      rect              = element_rect(fill = "transparent", colour = NA, color = NA, size = 0, linetype = 0),
      text              = element_text(family = font_family, face = "plain", colour = "black",
                                       size = font_size, hjust = 0.5, vjust = 0.5, angle = 0, lineheight = .9,
                                       margin = ggplot2::margin(), debug = FALSE),
      axis.text         = element_text(colour = "black", size = font_size),
      #axis.title        = element_text(face = "bold"),
      axis.text.x       = element_text(margin = ggplot2::margin(t = small_size / 4), vjust = 1),
      axis.text.y       = element_text(margin = ggplot2::margin(r = small_size / 4), hjust = 1, vjust = 0),
      axis.title.x      = element_text(
        margin = ggplot2::margin(t = small_size / 2, b = small_size / 4),
        hjust = 1
      ),
      axis.title.y      = element_text(
        angle = 90,
        margin = ggplot2::margin(r = small_size / 2, l = small_size / 4),
        hjust = 1
      ),
      axis.ticks        = axis.ticks,
      axis.ticks.y      = axis.ticks.y,
      axis.line         = element_blank(),
      legend.key        = element_blank(),
      legend.key.size   = grid::unit(1, "lines"),
      legend.text       = element_text(size = rel(small_rel)),
      legend.justification = c("left", "center"),
      panel.background  = element_blank(),
      panel.border      = element_blank(),
      # make grid lines
      panel.grid.major  = panel.grid.major,
      panel.grid.minor  = element_blank(),
      strip.text        = element_text(size = rel(small_rel)),
      strip.background  = element_rect(fill = color, colour = "grey50", size = 0),
      plot.background   = element_blank(),
      plot.title        = element_text(face = "bold",
                                       size = font_size,
                                       margin = ggplot2::margin(b = half_line), hjust = 0),

      complete = TRUE
    )
}
