#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(optparse)
  library(rmarkdown)
})

opts <- list(
  make_option("--sl_summary", type = "character", help = "Standardised sl_summary.tsv"),
  make_option("--ml_summary", type = "character", help = "Standardised ml_summary.tsv"),
  make_option("--sl_from_ml", type = "character", default = NULL, help = "raw_sl_from_ml_summary.tsv"),
  make_option("--loci_coverage", type = "character", help = "loci_covered_by_target_samples_info.tsv"),
  make_option("--aa_calls", type = "character", help = "collapsed_amino_acid_calls.tsv.gz"),
  make_option("--unassigned", type = "character", default = NULL, help = "unassigned_specimens.txt"),
  make_option("--population_assignment", type = "character", default = NULL, help = "Population assignment TSV"),
  make_option("--population_label", type = "character", default = "pop1"),
  make_option("--template", type = "character", default = "report.Rmd"),
  make_option("--output", type = "character", default = "plasmodiumdrugres_report.html"),
  make_option("--figures_dir", type = "character", default = "figures"),
  make_option(
    "--interactive",
    type = "logical",
    default = TRUE,
    help = "Render Plotly figures. Set FALSE for static ggplot PNGs. Default: %default"
  )
)

args <- parse_args(OptionParser(option_list = opts))
missing <- Filter(function(name) is.null(args[[name]]), c("sl_summary", "ml_summary", "loci_coverage", "aa_calls"))
if (length(missing) > 0) {
  stop("Missing required arguments: ", paste(paste0("--", missing), collapse = ", "), call. = FALSE)
}

optional_path <- function(path) {
  if (is.null(path) || !nzchar(path) || identical(path, "NULL") || !file.exists(path)) {
    return(NULL)
  }
  normalizePath(path, mustWork = TRUE)
}

output_dir <- dirname(args$output)
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
if (!isTRUE(args$interactive)) {
  dir.create(args$figures_dir, recursive = TRUE, showWarnings = FALSE)
}

rmarkdown::render(
  input = args$template,
  output_file = basename(args$output),
  output_dir = output_dir,
  knit_root_dir = getwd(),
  params = list(
    interactive = isTRUE(args$interactive),
    sl_summary = normalizePath(args$sl_summary, mustWork = TRUE),
    ml_summary = normalizePath(args$ml_summary, mustWork = TRUE),
    sl_from_ml = optional_path(args$sl_from_ml),
    loci_coverage = normalizePath(args$loci_coverage, mustWork = TRUE),
    aa_calls = normalizePath(args$aa_calls, mustWork = TRUE),
    unassigned = optional_path(args$unassigned),
    population_assignment = optional_path(args$population_assignment),
    population_label = args$population_label,
    figures_dir = args$figures_dir
  ),
  quiet = TRUE
)
