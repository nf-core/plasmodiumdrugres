#!/usr/bin/env Rscript

packagesToLoad <- c("tibble", "dplyr", "readr", "optparse")
invisible(lapply(packagesToLoad, library, warn.conflicts = FALSE, character.only = TRUE))

options(readr.show_col_types = FALSE)

returnMissingColumns <- function(tib, columns) {
    setdiff(columns, colnames(tib))
}

read_input_and_check_cols <- function(input_table_fnp, required_cols) {
    stopifnot(is.character(input_table_fnp))
    stopifnot(file.exists(input_table_fnp))
    input_table <- read_tsv(input_table_fnp)
    missing_cols <- returnMissingColumns(input_table, required_cols)
    if (length(missing_cols) > 0) {
        stop(
            paste0("Input ", input_table_fnp, " missing the following columns: ", paste0(missing_cols, collapse = ",")),
            call. = FALSE
        )
    }
    input_table
}

opts <- list(
    make_option(
        c("--population_map"),
        help = "TSV population assignment with identifier and population columns",
        type = "character"
    ),
    make_option(
        c("--population_col"),
        help = "Population label column. Default: %default",
        type = "character",
        default = "population"
    ),
    make_option(
        c("--identifier_col"),
        help = "Identifier column. Default: %default",
        type = "character",
        default = "specimen_name"
    ),
    make_option(
        c("--indexed_output"),
        help = "Output path for indexed population map",
        type = "character",
        default = "population_map_indexed.tsv"
    ),
    make_option(
        c("--lookup_output"),
        help = "Output path for population index lookup table",
        type = "character",
        default = "population_index_lookup.tsv"
    )
)

parser <- OptionParser(option_list = opts)
args <- parse_args(parser)

if (is.null(args$population_map)) {
    print_help(parser)
    stop("Missing required argument: --population_map", call. = FALSE)
}

population_map <- read_input_and_check_cols(
    args$population_map,
    c(args$identifier_col, args$population_col)
)

population_map[[args$identifier_col]] <- trimws(gsub("\r", "", population_map[[args$identifier_col]]))
population_map[[args$population_col]] <- trimws(gsub("\r", "", population_map[[args$population_col]]))

unique_pops <- sort(unique(population_map[[args$population_col]]))
n_pops <- length(unique_pops)
index_width <- max(3L, nchar(as.character(n_pops)))
population_index_map <- tibble(
    population = unique_pops,
    population_index = sprintf(paste0("popidx_%0", index_width, "d"), seq_len(n_pops))
)

population_map_indexed <- population_map %>%
    left_join(population_index_map, by = setNames("population", args$population_col))

write_tsv(
    population_index_map %>% select(population_index, population),
    args$lookup_output
)
write_tsv(population_map_indexed, args$indexed_output)
