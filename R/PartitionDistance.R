#' Compare Splits
#' 
#' @param x A matrix of bipartitions, perhaps generated by \code{\link{Tree2Splits}}.
#' @param cf A matrix of bipartitions against which to compare \code{x}.
#' 
#' @return A vector of six integers, listing the number of splits that (1)
#'         are present in \code{x}; (2) are present in \code{cf}; (3) are
#'         present in both trees; (4) are present in \code{x} but not \code{cf};
#'         (5) are present in \code{cf} but not \code{x}; and (6) the sum of the
#'         latter two values, i.e. the Robinson-Foulds distance.
#'         
#' @references {
#'  \insertRef{Estabrook1985}{SlowQuartet}
#'  \insertRef{Robinson1981}{SlowQuartet}
#' }       
#' @author Martin R. Smith
#' @export
CompareSplits <- function (x, cf) {
  x <- DropSingleSplits(x)
  cf <- DropSingleSplits(cf)
  SplitHash <- function (split) {
    min(
      sum(2 ^ (which(split) - 1)),
      sum(2 ^ (which(!split) - 1))
    )
  }
  x_hashes <- unique(apply(x, 2, SplitHash))
  cf_hashes <- unique(apply(cf, 2, SplitHash))
  common <- sum(x_hashes %in% cf_hashes)
  x_splits <- length(x_hashes)
  cf_splits <- length(cf_hashes)
  c(x_splits, cf_splits, 
    common, x_splits - common, cf_splits - common,
    x_splits + cf_splits - (2 * common))
}

#' Matching partitions
#' 
#' Calculates how many of the partitions present in tree A are also present in 
#' tree B, how many of the partitions in tree A are absent in tree B, and how
#' many of the partitions in tree B are absent in tree A.  The Robinson-Foulds
#' (symmetric partition) distance is the sum of the latter two quantities.
#' 
#' @template treesParam
#' @template treesCfParam
#' 
#' @return Returns a two dimensional array. 
#'         Columns correspond to the input trees; the first column will always
#'         report a perfect match as it compares the first tree to itself.
#'         Rows report the number of partitions that : 1, are present in 
#'         \code{trees[[1]]} and the corresponding input tree;
#'         2: are unresolved in (at least) one of trees[[1]] and the corresponding 
#'         input tree. Partitions that DIFFER between the two relevant trees can be 
#'         calculated by deducting the partitions in either of the other two
#'         categories from the total number of partitions, given by
#'         \code{(n_tip * 2) - 3}.
#'         
#'@seealso [MatchingQuartets]
#'         
#'  @references {
#'    \insertRef{Robinson1981}{SlowQuartet}
#'    \insertRef{Penny1985}{SlowQuartet}
#'  }
#' @author Martin R. Smith
#' @export
MatchingSplits <- function (trees, cf=NULL) {
  if (!is.null(cf)) trees <- UnshiftTree(cf, trees)
  
  treeStats <- vapply(trees, function (tr)
    c(tr$Nnode, length(tr$tip.label)), double(2))
  if (length(unique(treeStats[2, ])) > 1) {
    stop("All trees must have the same number of tips")
  }
  tree1Labels <- trees[[1]]$tip.label
  trees <- lapply(trees, RenumberTips, tipOrder = tree1Labels)
  splits <- lapply(trees, Tree2Splits)
  ret <- vapply(splits, CompareSplits, cf=splits[[1]], double(6))
  rownames(ret) <- c('cf', 'ref',
                     'cf_and_ref', 'cf_not_ref', 'ref_not_cf',
                     'RF_dist')
  
  # Return:
  if (is.null(cf)) ret else ret[, -1]
}
