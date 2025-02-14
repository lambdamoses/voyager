#' Plot local results
#'
#' Plot results of local spatial analyses in space, such as local Getis-Ord Gi*
#' values.
#'
#' Many local spatial analyses return a data frame or matrix as the results,
#' whose columns can be the statistic of interest at each location, its
#' variance, expected value from permutation, p-value, and etc. The
#' \code{attribute} argument specifies which column to use when there are
#' multiple columns. Below are the defaults for each local method supported by
#' this package what what they mean:
#'
#' \describe{
#' \item{\code{localmoran} and \code{localmoran_perm}}{\code{Ii}, local Moran's
#' I statistic at each location.}
#' \item{\code{localC_perm}}{\code{localC}, the local Geary C statistic at each
#' location.}
#' \item{\code{localG} and \code{localG_perm}}{\code{localG}, the local
#' Getis-Ord Gi or Gi* statistic. If \code{include_self = TRUE} when
#' \code{\link{calculateUnivariate}} or \code{\link{runUnivariate}} was called,
#' then it would be Gi*. Otherwise it's Gi.}
#' \item{\code{LOSH} and \code{LOSH.mc}}{\code{Hi}, local spatial
#' heteroscedasticity}
#' \item{\code{moran.plot}}{\code{wx}, the average of the value of each neighbor
#' of each location. Moran plot is best plotted as a scatter plot of \code{wx}
#' vs \code{x}. See \code{\link{moranPlot}}.}
#' }
#'
#' Other local methods not listed above return vectors as results. For instance,
#' \code{localC} returns a vector by default, which is the local Geary's C
#' statistic.
#'
#' @inheritParams plotSpatialFeature
#' @inheritParams plotCorrelogram
#' @inheritParams plotDimLoadings
#' @param name Which local spatial results. Use
#'   \code{\link[SpatialFeatureExperiment]{localResultNames}} to see which types
#'   of results have already been calculated.
#' @param type An \code{\link{SFEMethod}} object or a string corresponding to
#'   the name of one of such objects in the environment. If the
#'   \code{localResult} of interest was manually added outside
#'   \code{\link{runUnivariate}} and \code{\link{runBivariate}}, so the method
#'   is not recorded, then the \code{type} argument can be used to specify the
#'   method to properly get the title and labels. By default, this argument is
#'   set to be the same as argument \code{name}. If the method parameters are
#'   recorded, then the \code{type} argument is ignored.
#' @param features Character vector of vectors. To see which features have the
#'   results of a given type, see
#'   \code{\link[SpatialFeatureExperiment]{localResultFeatures}}.
#' @param attribute Which field in the local results of the type and features.
#'   If the result of each feature is a vector, the this argument is ignored.
#'   But if the result is a data frame or a matrix, then this is the column name
#'   of the result, such as "Ii" for local Moran's I. For each local spatial
#'   analysis method, there's a default attribute. See Details. Use
#'   \code{\link[SpatialFeatureExperiment]{localResultAttrs}}.
#' @note While this function shares internals with
#'   \code{\link{plotSpatialFeature}}, there are some important differences. In
#'   \code{\link{plotSpatialFeature}}, the \code{annotGeometry} is indeed only
#'   used for annotation and the protagonist is the \code{colGeometry}, since
#'   it's easy to directly use \code{ggplot2} to plot the data in
#'   \code{annotGeometry} \code{sf} data frames while overlaying
#'   \code{annotGeometry} and \code{colGeometry} involves more complicated code.
#'   In contrast, in this function, local results for \code{annotGeometry} can
#'   be plotted separately without anything related to \code{colGeometry}. Note
#'   that when \code{annotGeometry} local results are plotted without
#'   \code{colGeometry}, the \code{annot_*} arguments are ignored. Use the other
#'   arguments for aesthetics as if it's for \code{colGeometry}.
#' @return A \code{ggplot2} object if plotting one feature. A \code{patchwork}
#'   object if plotting multiple features.
#' @concept Plot spatial analysis results
#' @importFrom ggplot2 ggtitle
#' @importFrom patchwork plot_annotation
#' @export
#' @examples
#' library(SpatialFeatureExperiment)
#' library(SFEData)
#' library(scater)
#' sfe <- McKellarMuscleData("small")
#' sfe <- sfe[,sfe$in_tissue]
#' colGraph(sfe, "visium") <- findVisiumGraph(sfe)
#' feature_use <- rownames(sfe)[1]
#' sfe <- logNormCounts(sfe)
#' sfe <- runUnivariate(sfe, "localmoran", feature_use)
#' # Which types of results are available?
#' localResultNames(sfe)
#' # Which features for localmoran?
#' localResultFeatures(sfe, "localmoran")
#' # Which columns does the localmoran results have?
#' localResultAttrs(sfe, "localmoran", feature_use)
#' plotLocalResult(sfe, "localmoran", feature_use, "Ii",
#'     colGeometryName = "spotPoly"
#' )
#'
#' # For annotGeometry
#' # Make sure it's type POLYGON
#' annotGeometry(sfe, "myofiber_simplified") <-
#'     sf::st_buffer(annotGeometry(sfe, "myofiber_simplified"), 0)
#' annotGraph(sfe, "poly2nb_myo") <-
#'     findSpatialNeighbors(sfe,
#'         type = "myofiber_simplified", MARGIN = 3,
#'         method = "poly2nb", zero.policy = TRUE
#'     )
#' sfe <- annotGeometryUnivariate(sfe, "localmoran",
#'     features = "area",
#'     annotGraphName = "poly2nb_myo",
#'     annotGeometryName = "myofiber_simplified",
#'     zero.policy = TRUE
#' )
#' plotLocalResult(sfe, "localmoran", "area", "Ii",
#'     annotGeometryName = "myofiber_simplified",
#'     size = 0.3, color = "cyan"
#' )
#' plotLocalResult(sfe, "localmoran", "area", "Z.Ii",
#'     annotGeometryName = "myofiber_simplified"
#' )
#' # don't use annot_* arguments when annotGeometry is plotted without colGeometry
plotLocalResult <- function(sfe, name, features, attribute = NULL,
                            sample_id = "all",
                            colGeometryName = NULL, annotGeometryName = NULL,
                            rowGeometryName = NULL,
                            rowGeometryFeatures = NULL,
                            ncol = NULL, ncol_sample = NULL,
                            annot_aes = list(), annot_fixed = list(),
                            tx_fixed = list(), bbox = NULL, tx_file = NULL,
                            image_id = NULL, channel = NULL, maxcell = 5e+5,
                            aes_use = c("fill", "color", "shape", "linetype"),
                            divergent = FALSE, diverge_center = NULL,
                            annot_divergent = FALSE,
                            annot_diverge_center = NULL,
                            size = 0.5, shape = 16, linewidth = 0, linetype = 1, alpha = 1,
                            color = "black", fill = "gray80",
                            swap_rownames = NULL,
                            scattermore = FALSE, pointsize = 0, bins = NULL,
                            summary_fun = sum, hex = FALSE, show_axes = FALSE,
                            dark = FALSE, palette = colorRampPalette(c("black", "white"))(255),
                            normalize_channels = FALSE,
                            type = name, ...) {
    aes_use <- match.arg(aes_use)
    sample_id <- .check_sample_id(sfe, sample_id, one = FALSE)
    if (!is.null(colGeometryName)) {
        pred <- any(features %in% names(colGeometry(sfe, colGeometryName,
                                                    sample_id = "all")))
        cg_name <- if (pred) colGeometryName else NULL
    } else cg_name <- NULL
    if (!is.null(annotGeometryName)) {
        pred <- any(features %in% names(annotGeometry(sfe, annotGeometryName,
                                                      sample_id = "all")))
        ag_name <- if (pred) annotGeometryName else NULL
    } else ag_name <- NULL
    c(rowGeometryName, rowGeometryFeatures) %<-%
        .getRowGeometryFeatures(sfe, features, rowGeometryName, rowGeometryFeatures)
    params <- getParams(sfe, name, local = TRUE,
                        colGeometryName = cg_name,
                        annotGeometryName = ag_name)
    # params NULL if localResults manually added outside runUnivariate
    if (is.null(params)) {
        if (is.character(type))
            type <- get(type, mode = "S4")
    } else type <- get(params$name, mode = "S4")

    if (is.null(attribute)) attribute <- info(type, "default_attr")
    base <- info(type, "title")
    title_use <- if (is.na(attribute)) base else paste0(base, " (", attribute, ")")

    values <- .get_localResult_values(sfe, name, type, features, attribute,
        sample_id, colGeometryName,
        annotGeometryName,
        show_symbol = !is.null(swap_rownames), swap_rownames = swap_rownames
    )
    # When Ensembl IDs are supplied but show gene symbols
    # colnames of values are gene symbols
    inds <- !names(values) %in% features
    if (any(inds))
        features[inds] <- rowData(sfe)[features[inds], swap_rownames]
    values <- values[,features, drop = FALSE]
    # Somewhat different from plotSpatialFeature
    # Here results for annotGeometries should be able to be plotted on its own
    # without specifying colGeometries.
    # However, colGeometries would still have primacy.
    # For now all panels must all use the same colGeometry
    # or the same annotGeometry.
    if (!is.null(colGeometryName)) {
        out <- .plotSpatialFeature(
            sfe, values, colGeometryName, sample_id,
            ncol,
            ncol_sample, annotGeometryName, annot_aes,
            annot_fixed, tx_fixed, bbox, image_id, aes_use, divergent,
            diverge_center, annot_divergent,
            annot_diverge_center, size, shape, linewidth, linetype,
            alpha, color, fill,
            scattermore = scattermore, pointsize = pointsize,
            bins = bins, summary_fun = summary_fun, hex = hex,
            maxcell = maxcell, channel = channel, show_axes = show_axes,
            dark = dark, palette = palette, normalize_channels = normalize_channels,
            rowGeometryName = rowGeometryName,
            rowGeometryFeatures = rowGeometryFeatures, tx_file = tx_file, ...
        )
    } else if (is.null(annotGeometryName)) {
        stop("At least one of colGeometryName and annotGeometryName must be specified.")
    } else {
        df <- annotGeometry(sfe, annotGeometryName, sample_id)
        df <- df[,setdiff(names(df), names(values))]
        df <- cbind(df[,"sample_id"], values)
        df <- .crop(df, bbox)
        if (!is.null(image_id)) img_df <- .get_img_df(sfe, sample_id, image_id,
                                                      channel, bbox, maxcell,
                                                      normalize_channels)
        else img_df <- NULL
        if (inherits(img_df, "DataFrame") && !nrow(img_df)) img_df <- NULL
        if (!is.null(rowGeometryName)) {
            tx_df <- .get_tx_df(sfe, data_dir = NULL, tech = NULL, file = NULL,
                                sample_id = sample_id, spatialCoordsNames = c("X", "Y"),
                                gene_col = "gene", bbox = bbox, gene = rowGeometryFeatures,
                                return_sf = TRUE, rowGeometryName = rowGeometryName,
                                geoparquet_file = tx_file)
        } else tx_df <- NULL
        out <- .wrap_spatial_plots(df,
            annot_df = NULL, img_df = img_df, type_annot = NULL, channel = channel,
            values = values, aes_use = aes_use,
            annot_aes = list(), annot_fixed = list(), tx_fixed = tx_fixed,
            size, shape, linewidth, linetype, alpha,
            color, fill, ncol, ncol_sample, divergent,
            diverge_center, annot_divergent = FALSE,
            annot_diverge_center = NULL, scattermore = scattermore,
            pointsize = pointsize, bins = bins, summary_fun = summary_fun,
            hex = hex, maxcell = maxcell, show_axes = show_axes, dark = dark,
            palette = palette, tx_df = tx_df,
            rowGeometryFeatures = rowGeometryFeatures,...
        )
    }
    # Add title to not to confuse with gene expression
    if (inherits(out, "patchwork")) {
        out <- out + plot_annotation(title = title_use)
    } else {
        out <- out + ggtitle(title_use)
    }
    out
}
