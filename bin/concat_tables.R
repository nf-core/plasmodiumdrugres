#!/usr/bin/env Rscript

# Concatenate per-population summary TSVs deterministically.

suppressMessages(library(optparse))
suppressMessages(library(readr))
suppressMessages(library(dplyr))

opts <- list(
  make_option(c("--sl-files"), type = "character", help = "Comma-separated list of sl_summary TSVs"),
  make_option(c("--ml-files"), type = "character", help = "Comma-separated list of ml_summary TSVs"),
  make_option(c("--sl-from-ml-files"), type = "character", help = "Comma-separated list of sl_from_ml_summary TSVs"),
  make_option(
    c("--loci-of-interest"),
    type = "character",
    default = NULL,
    help = "Loci of interest table. When it has a gene column, that name is added to the summary tables."
  ),
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

empty_ml_summary <- function(include_gene = FALSE) {
  df <- tibble(
    population = character(),
    group_id = character(),
    variant = character(),
    freq = double()
  )
  if (include_gene) {
    df <- df %>% mutate(gene = character()) %>% relocate(gene, .after = variant)
  }
  df
}

# Named vector of gene_id -> gene, or NULL when the loci table has no gene column.
read_gene_lookup <- function(path) {
  if (is.null(path) || is.na(path) || !nzchar(path)) {
    return(NULL)
  }
  if (!file.exists(path)) {
    stop(sprintf("Loci of interest file does not exist: '%s'", path))
  }
  loci <- read_tsv(path, show_col_types = FALSE)
  if (!("gene" %in% colnames(loci))) {
    return(NULL)
  }
  if (!("gene_id" %in% colnames(loci))) {
    stop("Loci of interest file has a gene column but no gene_id column")
  }
  lookup <- loci %>%
    transmute(
      gene_id = trimws(as.character(.data$gene_id)),
      gene = trimws(as.character(.data$gene))
    ) %>%
    distinct()
  if (any(is.na(lookup$gene_id) | !nzchar(lookup$gene_id))) {
    stop("Loci of interest gene_id column contains missing values")
  }
  if (any(is.na(lookup$gene) | !nzchar(lookup$gene))) {
    stop("Loci of interest gene column contains missing values")
  }
  conflicts <- lookup %>%
    count(.data$gene_id) %>%
    filter(.data$n > 1)
  if (nrow(conflicts) > 0) {
    stop(
      "gene_id maps to more than one gene name: ",
      paste(conflicts$gene_id, collapse = ", ")
    )
  }
  stats::setNames(lookup$gene, lookup$gene_id)
}

# One short gene name per variant-string gene block, in that same order.
# PF3D7_0417200.1:51_59:I_R;PF3D7_0810800.1:437:G -> dhfr-ts;dhps
genes_for_variants <- function(variants, lookup) {
  vapply(variants, function(variant) {
    if (is.na(variant) || !nzchar(variant)) {
      stop("Cannot add gene column: variant is missing")
    }
    parts <- strsplit(variant, ";", fixed = TRUE)[[1]]
    gene_ids <- sub(":.*$", "", parts)
    unknown <- gene_ids[is.na(match(gene_ids, names(lookup)))]
    if (length(unknown) > 0) {
      stop(
        "No gene name for gene_id(s) ",
        paste(unique(unknown), collapse = ", "),
        " in variant '",
        variant,
        "'"
      )
    }
    paste(unname(lookup[gene_ids]), collapse = ";")
  }, character(1), USE.NAMES = FALSE)
}

add_gene_column <- function(df, lookup) {
  if (is.null(lookup)) {
    return(df)
  }
  if (!("variant" %in% colnames(df))) {
    stop("Cannot add gene column: summary table has no variant column")
  }
  gene <- if (nrow(df) == 0) character() else genes_for_variants(df$variant, lookup)
  df %>%
    mutate(gene = gene) %>%
    relocate(gene, .after = variant)
}

insert_gene_col <- function(cols, include_gene) {
  if (!include_gene) {
    return(cols)
  }
  append(cols, "gene", after = match("variant", cols))
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

standardize_sl_summary <- function(df, gene_lookup = NULL) {
  missing <- setdiff(SL_SUMMARY_COLS, colnames(df))
  if (length(missing) > 0) {
    stop(
      "sl_summary missing required columns: ",
      paste(missing, collapse = ", ")
    )
  }
  include_gene <- !is.null(gene_lookup)
  df %>%
    add_gene_column(gene_lookup) %>%
    select(all_of(insert_gene_col(SL_SUMMARY_COLS, include_gene)))
}

standardize_ml_summary <- function(df, gene_lookup = NULL) {
  include_gene <- !is.null(gene_lookup)
  # No ML inputs (e.g. unit tests with empty channels): emit header-only stub.
  if (ncol(df) == 0) {
    return(empty_ml_summary(include_gene))
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
  df %>%
    add_gene_column(gene_lookup) %>%
    select(all_of(insert_gene_col(cols, include_gene)))
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

gene_lookup <- read_gene_lookup(args$`loci-of-interest`)
sl_df <- standardize_sl_summary(sl_concat, gene_lookup)
ml_df <- standardize_ml_summary(ml_concat, gene_lookup)

write_tsv(sl_df, args$`sl-out`)
write_tsv(ml_df, args$`ml-out`)
