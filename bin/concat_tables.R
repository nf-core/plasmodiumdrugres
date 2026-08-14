#!/usr/bin/env Rscript

# Concatenate per-population summary TSVs deterministically.

suppressMessages(library(optparse))
suppressMessages(library(readr))
suppressMessages(library(dplyr))

opts <- list(
  make_option(c("--sl-files"), type = "character", help = "Comma-separated list of sl_summary TSVs"),
  make_option(c("--ml-files"), type = "character", help = "Comma-separated list of ml_summary TSVs"),
  make_option(c("--sl-from-ml-files"), type = "character", help = "Comma-separated list of sl_from_ml_summary TSVs"),
  make_option(c("--sl-out"), type = "character", default = "sl_summary.tsv"),
  make_option(c("--ml-out"), type = "character", default = "ml_summary.tsv"),
  make_option(
    c("--raw-out-dir"),
    type = "character",
    default = "raw_summaries",
    help = "Directory for concatenated summary tables before column standardization"
  )
)

parser <- OptionParser(option_list = opts)
args <- parse_args(parser)

SL_SUMMARY_COLS <- c("population", "variant", "prev", "sample_count", "sample_total", "freq")

ML_SUMMARY_REQUIRED_COLS <- c("population", "group_id", "variant")
ML_SUMMARY_OPTIONAL_COLS <- c("prev", "sample_count", "sample_total")
ML_SUMMARY_FREQ_COL <- "freq"

split_files <- function(x) {
  if (is.null(x) || is.na(x) || !nzchar(x)) return(character(0))
  parts <- strsplit(x, ",", fixed = TRUE)[[1]]
  parts <- parts[nzchar(parts)]
  return(parts)
}

files_to_df <- function(files) {
  if (length(files) == 0) {
    return(tibble())
  }
  # Keep column types stable-ish; most columns are numeric but we mostly sort on strings.
  dfs <- lapply(files, function(f) {
    if (!file.exists(f)) {
      stop(sprintf("Input file does not exist: '%s'", f))
    }
    read_tsv(f, show_col_types = FALSE)
  })
  bind_rows(dfs)
}

empty_ml_summary <- function() {
  tibble(
    population = character(),
    group_id = character(),
    variant = character(),
    freq = double()
  )
}

empty_sl_from_ml_summary <- function() {
  tibble(
    population = character(),
    group_id = character(),
    variant = character(),
    sample_total = double(),
    allele_total = double(),
    allele_count = double(),
    sample_count = double(),
    freq = double(),
    prev = double()
  )
}

standardize_sl_summary <- function(df) {
  missing <- setdiff(SL_SUMMARY_COLS, colnames(df))
  if (length(missing) > 0) {
    stop(
      "sl_summary missing required columns: ",
      paste(missing, collapse = ", ")
    )
  }
  df %>% select(all_of(SL_SUMMARY_COLS))
}

standardize_ml_summary <- function(df) {
  # No ML inputs (e.g. unit tests with empty channels): emit header-only stub.
  if (ncol(df) == 0) {
    return(empty_ml_summary())
  }

  required <- c(ML_SUMMARY_REQUIRED_COLS, ML_SUMMARY_FREQ_COL)
  missing <- setdiff(required, colnames(df))
  if (length(missing) > 0) {
    stop(
      "ml_summary missing required columns: ",
      paste(missing, collapse = ", ")
    )
  }

  optional_present <- ML_SUMMARY_OPTIONAL_COLS[
    ML_SUMMARY_OPTIONAL_COLS %in% colnames(df)
  ]
  cols <- c(ML_SUMMARY_REQUIRED_COLS, optional_present, ML_SUMMARY_FREQ_COL)
  df %>% select(all_of(cols))
}

maybe_sort <- function(df, sort_cols = c("population", "variant")) {
  # Sort to ensure deterministic output across runs.
  if (all(sort_cols %in% colnames(df))) {
    return(df %>% arrange(across(all_of(sort_cols))))
  }
  return(df)
}

sl_files <- split_files(args$`sl-files`)
ml_files <- split_files(args$`ml-files`)
sl_from_ml_files <- split_files(args$`sl-from-ml-files`)

sl_concat <- files_to_df(sl_files) %>% maybe_sort()
ml_concat <- files_to_df(ml_files) %>%
  maybe_sort(c("population", "group_id", "variant"))
sl_from_ml_concat <- maybe_sort(files_to_df(sl_from_ml_files))

# Preserve header-only stubs when ML inputs are absent.
if (ncol(ml_concat) == 0) {
  ml_concat <- empty_ml_summary()
}
if (ncol(sl_from_ml_concat) == 0) {
  sl_from_ml_concat <- empty_sl_from_ml_summary()
}

dir.create(args$`raw-out-dir`, showWarnings = FALSE, recursive = TRUE)
write_tsv(sl_concat, file.path(args$`raw-out-dir`, "raw_sl_summary.tsv"))
write_tsv(ml_concat, file.path(args$`raw-out-dir`, "raw_ml_summary.tsv"))
write_tsv(
  sl_from_ml_concat,
  file.path(args$`raw-out-dir`, "raw_sl_from_ml_summary.tsv")
)

sl_df <- sl_concat %>% standardize_sl_summary()
ml_df <- ml_concat %>% standardize_ml_summary()

write_tsv(sl_df, args$`sl-out`)
write_tsv(ml_df, args$`ml-out`)
