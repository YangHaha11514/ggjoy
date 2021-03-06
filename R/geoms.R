#' Plot a ridgeline (line with filled area underneath)
#'
#' @examples
#'
#' d <- data.frame(x = rep(1:5, 3), y = c(rep(0, 5), rep(1, 5), rep(3, 5)),
#'                 height = c(0, 1, 3, 4, 0, 1, 2, 3, 5, 4, 0, 5, 4, 4, 1))
#' ggplot(d, aes(x, y, height = height, group = y)) + geom_ridgeline(fill="lightblue")
#'
#' @export
geom_ridgeline <- function(mapping = NULL, data = NULL, stat = "identity",
                      position = "identity", na.rm = FALSE, show.legend = NA,
                      inherit.aes = TRUE, ...) {
  layer(
    data = data,
    mapping = mapping,
    stat = stat,
    geom = GeomRidgeline,
    position = position,
    show.legend = show.legend,
    inherit.aes = inherit.aes,
    params = list(
      na.rm = na.rm,
      ...
    )
  )
}

#' @export
GeomRidgeline <- ggproto("GeomRidgeline", GeomRibbon,
  default_aes = plyr::defaults(
    aes(colour = "black", fill = "grey80", y = 0, size = 0.5, linetype = 1,
        min_height = 0, alpha = NA),
    GeomRibbon$default_aes
  ),

  required_aes = c("x", "y", "height"),

  setup_data = function(data, params) {
    transform(data, ymin = y, ymax = y + height)
  },

  draw_panel = function(self, data, panel_params, coord, ...) {
    groups <- split(data, factor(data$group))

    # sort list so highest ymin values are in the front
    # we take a shortcut here and look only at the first ymin value given
    o <- order(unlist(lapply(groups, function(data){data$ymin[1]})), decreasing = TRUE)
    groups <- groups[o]

    grobs <- lapply(groups, function(group) {
      self$draw_group(group, panel_params, coord, ...)
    })

    ggname(snake_class(self), gTree(
      children = do.call("gList", grobs)
    ))
  },

  draw_group = function(data, panel_params, coord, na.rm = FALSE) {
    if (na.rm) data <- data[stats::complete.cases(data[c("x", "ymin", "ymax")]), ]
    data <- data[order(data$group, data$x), ]

    # remove all points that fall below the minimum height
    data$ymax[data$height < data$min_height] <- NA

    # Check that aesthetics are constant
    aes <- unique(data[c("colour", "fill", "size", "linetype", "alpha")])
    if (nrow(aes) > 1) {
      stop("Aesthetics can not vary with a ribbon")
    }
    aes <- as.list(aes)

    # Instead of removing NA values from the data and plotting a single
    # polygon, we want to "stop" plotting the polygon whenever we're
    # missing values and "start" a new polygon as soon as we have new
    # values.  We do this by creating an id vector for polygonGrob that
    # has distinct polygon numbers for sequences of non-NA values and NA
    # for NA values in the original data.  Example: c(NA, 2, 2, 2, NA, NA,
    # 4, 4, 4, NA)
    missing_pos <- !stats::complete.cases(data[c("x", "ymin", "ymax")])
    ids <- cumsum(missing_pos) + 1
    ids[missing_pos] <- NA

    # munching for polygon
    positions <- plyr::summarise(data,
                                 x = c(x, rev(x)), y = c(ymax, rev(ymin)), id = c(ids, rev(ids)))
    munched_poly <- ggplot2::coord_munch(coord, positions, panel_params)

    # munching for line
    positions <- plyr::summarise(data, x = x, y = ymax, id = ids)
    munched_line <- ggplot2::coord_munch(coord, positions, panel_params)

    lg <- ggname("geom_ridgeline",
           grid::polylineGrob(
                        munched_line$x, munched_line$y, id = munched_line$id,
                        default.units = "native",
                        gp = grid::gpar(
                          col = aes$colour,
                          lwd = aes$size * .pt,
                          lty = aes$linetype)
                      ))

    ag <- ggname("geom_ridgeline",
                 grid::polygonGrob(
                   munched_poly$x, munched_poly$y, id = munched_poly$id,
                   default.units = "native",
                   gp = grid::gpar(
                     fill = alpha(aes$fill, aes$alpha),
                     lty = 0)
                 ))
    grid::grobTree(ag, lg)
    }
)



#' Joy plot based on ridgelines
#'
#' `geom_joy` arranges multiple density plots in a staggered fashion, as in the cover of the famous Joy Division album.
#'
#' @name geom_joy
#' @importFrom ggplot2 layer
#' @export
#' @examples
#' ggplot(iris, aes(x=Sepal.Length, y=Species, group=Species, height = ..density..)) +
#'   geom_joy() +
#'   scale_y_discrete(expand=c(0.01, 0)) +
#'   scale_x_continuous(expand=c(0.01, 0)) +
#'   theme_joy()
#'
#'
#' # set the scale argument in `geom_joy2()` to determine how much overlap there is among the plots
#' ggplot(diamonds, aes(x=price, y=cut, group=cut, height=..density..)) +
#'   geom_joy(scale=4) +
#'   scale_y_discrete(expand=c(0.01, 0)) +
#'   scale_x_continuous(expand=c(0.01, 0)) +
#'   theme_joy()
#'
#' # the same figure with fun colors
#' ggplot(diamonds, aes(x=price, y=cut, fill=cut, height=..density..)) +
#'   geom_joy(scale=4) +
#'   scale_y_discrete(expand=c(0.01, 0)) +
#'   scale_x_continuous(expand=c(0.01, 0)) +
#'   scale_fill_brewer(palette = 4) +
#'   theme_joy() + theme(legend.position="none")
#'
#' # evolution of movie lengths over time
#' # requires the ggplot2movies package
#' library(ggplot2movies)
#' ggplot(movies, aes(x=length, y=year, group=year, height=..density..)) +
#'   geom_joy(scale=10, size=0.25) + theme_joy() +
#'   scale_x_log10(limits=c(1, 500), breaks=c(1,10,100,1000), expand=c(0.01, 0)) +
#'   scale_y_reverse(breaks=c(2000, 1980, 1960, 1940, 1920, 1900), expand=c(0.01, 0))
geom_joy <- function(mapping = NULL, data = NULL, stat = "density",
                     position = "identity", na.rm = FALSE, show.legend = NA,
                     scale = 1.8, rel_min_height = 0.01,
                     inherit.aes = TRUE, ...) {
  layer(
    data = data,
    mapping = mapping,
    stat = stat,
    geom = GeomJoy,
    position = position,
    show.legend = show.legend,
    inherit.aes = inherit.aes,
    params = list(
      na.rm = na.rm,
      scale = scale,
      rel_min_height = rel_min_height,
      ...
    )
  )
}

#' @rdname geom_joy
#' @format NULL
#' @usage NULL
#' @importFrom ggplot2 ggproto GeomRibbon
#' @importFrom grid gTree gList
#' @export
GeomJoy <- ggproto("GeomJoy", GeomRidgeline,
  default_aes =
    aes(colour = "black",
        fill = "grey70",
        size = 0.5,
        linetype = 1,
        alpha = NA,
        scale = 1.8,
        rel_min_height = 0.01),

   required_aes = c("x", "y", "height"),

   setup_data = function(data, params) {
     yrange = max(data$y) - min(data$y)
     hmax = max(data$height)
     n = length(unique(data$y))
     # calculate internal scale
     if (n>1) iscale = yrange/((n-1)*hmax)
     else iscale = 1

     transform(data,
               ymin = y,
               ymax = y + iscale*params$scale*height,
               min_height = hmax*params$rel_min_height)
  }
)


#' Joy plot based on closed polygons
#'
#' `geom_joy2` is similar to `geom_joy` but draws closed polygons rather than ridgelines.
#'
#' @name geom_joy2
#' @importFrom ggplot2 layer
#' @export
#' @examples
#' ggplot(iris, aes(x=Sepal.Length, y=Species, group=Species, height = ..density..)) +
#'   geom_joy2() +
#'   scale_y_discrete(expand=c(0.01, 0)) +
#'   scale_x_continuous(expand=c(0.01, 0)) +
#'   theme_joy()
#'
#'
#' # set the scale argument in `geom_joy2()` to determine how much overlap there is among the plots
#' ggplot(diamonds, aes(x=price, y=cut, group=cut, height=..density..)) +
#'   geom_joy2(scale=4) +
#'   scale_y_discrete(expand=c(0.01, 0)) +
#'   scale_x_continuous(expand=c(0.01, 0)) +
#'   theme_joy()
geom_joy2 <- function(mapping = NULL, data = NULL, stat = "density",
                      position = "identity", na.rm = FALSE, show.legend = NA, scale = 1.8,
                      inherit.aes = TRUE, ...) {
  layer(
    data = data,
    mapping = mapping,
    stat = stat,
    geom = GeomJoy2,
    position = position,
    show.legend = show.legend,
    inherit.aes = inherit.aes,
    params = list(
      na.rm = na.rm,
      scale = scale,
      ...
    )
  )
}

#' @rdname geom_joy2
#' @format NULL
#' @usage NULL
#' @importFrom ggplot2 ggproto GeomRibbon
#' @importFrom grid gTree gList
#' @export
GeomJoy2 <- ggproto("GeomJoy2", GeomRibbon,
  default_aes =
    aes(colour = "black",
        fill = "grey70",
        size = 0.5,
        linetype = 1,
        alpha = NA,
        scale = 2),

  required_aes = c("x", "y", "height"),

  setup_data = function(data, params) {
    yrange = max(data$y) - min(data$y)
    hmax = max(data$height)
    n = length(unique(data$y))
    # calculate internal scale
    if (n>1) iscale = yrange/((n-1)*hmax)
    else iscale = 1

    transform(data, ymin = y, ymax = y + iscale*params$scale*height)
  },

  draw_panel = function(self, data, panel_params, coord, ...) {
    groups <- split(data, factor(data$group))

    # sort list so highest ymin values are in the front
    # we take a shortcut here and look only at the first ymin value given
    o <- order(unlist(lapply(groups, function(data){data$ymin[1]})), decreasing = TRUE)
    groups <- groups[o]

    grobs <- lapply(groups, function(group) {
      self$draw_group(group, panel_params, coord, ...)
    })

    ggname(snake_class(self), gTree(
      children = do.call("gList", grobs)
    ))
  }
)

