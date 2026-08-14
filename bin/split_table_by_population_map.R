#!/usr/bin/env Rscript

# loading packages
packagesToLoad = c("tibble", "dplyr", "readr", "optparse")

# silence conflict warnings to make script more "silent"
loaded = lapply(packagesToLoad, library, warn.conflicts = F, character.only = TRUE)

options(readr.show_col_types = FALSE)
options(dplyr.summarise.inform = FALSE)

# function to get not in (makes it easier than doing !(test %in% test_set) )
`%!in%` <- Negate(`%in%`)

#' Find missing columns from a tibble
#'
#' @param tib the tibble to check
#' @param columns the columns to check for
#'
#' @return returns any missing columns
returnMissingColumns <-function(tib, columns){
    setdiff(columns, colnames(tib))
}

read_input_and_check_cols <- function(input_table_fnp, required_cols){
    # Check input arguments
    stopifnot(is.character(input_table_fnp))
    stopifnot(file.exists(input_table_fnp))
    # read in allele table and make sure it has specimen_name column
    input_table <- read_tsv(input_table_fnp)
    missing_cols = returnMissingColumns(input_table, required_cols)
    if (length(missing_cols) > 0) {
        stop(
            paste0("Input ", input_table_fnp, " missing the following columns : ", paste0(missing_cols, collapse = ",")),
            call. = FALSE
        )
    }
    return(input_table)
}

# Set up options
#' Check for required arguments, and report which are missing
#'
#' @param parser the parser created from optparse
#' @param arg the parsed arguments from optparse
#' @param required_args the required arguments (without the --)
#'
#' @return returns void if all required arguments
checkOptparseRequiredArgsThrow <- function(parser, arg, required_args){
    missing <- setdiff(required_args, names(arg))
    if(length(missing) > 0){
        missing = paste0("--", missing)
        print_help(parser)
        stop(paste0("mssing the following arguments: ", paste0(missing, collapse = ", ")))
    }
}


opts <- list(
    make_option(
        c("--input_table_fnp"),
        help = "TSV of the table to be split, needs at minimum the column provided by --identifier_col",
        type = "character"
    ),
    make_option(
        c("--population_map"),
        help = "TSV of population map, needs at minimum the columns provided by --identifier_col and --split_col",
        type = "character"
    ),
    make_option(
        c("--output_stub"),
        help = "Output file name stub, output will be [POPULATION_INDEX][OUTPUTSTUB]",
        type = "character"
    ),
    make_option(
        c("--output_directory"),
        help = "Directory to output split table. Default: %default",
        type = "character",
        default = "./"
    ),
    make_option(
        c("--split_col"),
        help = "Internal population index column to split on. Default: %default",
        type = "character",
        default = "population_index"
    ),
    make_option(
        c("--identifier_col"),
        help = "Identifer column to match between the population map and the table to split Default: %default",
        type = "character",
        default = "specimen_name"
    ),
    make_option(
        c("--unmapped_identifiers_output"),
        help = "otuput file name for unmapped_identifers.txt, if left as default will be written in the --output_directory, otherwise set to set a new ouput location and name: Default: %default",
        type = "character",
        default = "unmapped_identifers.txt"
    )
)

# Parse command-line arguments
parser <- OptionParser(option_list = opts)
args <- parse_args(parser)

checkOptparseRequiredArgsThrow(parser, args, c("input_table_fnp", "population_map", "output_stub"))

population_map = read_input_and_check_cols(
    args$population_map,
    c(args$identifier_col, args$split_col)
) %>%
    select(all_of(c(args$identifier_col, args$split_col))) %>%
    distinct()

population_map[[args$identifier_col]] <- trimws(gsub("\r", "", population_map[[args$identifier_col]]))
population_map[[args$split_col]] <- trimws(gsub("\r", "", population_map[[args$split_col]]))

input_table = read_input_and_check_cols(args$input_table_fnp, c(args$identifier_col)) %>%
    left_join(population_map, by = c(args$identifier_col))

input_table_with_pop = input_table %>%
    filter(!is.na(.data[[args$split_col]]))

input_table_with_no_pop = input_table %>%
    filter(is.na(.data[[args$split_col]]))

input_table_with_pop_split = split(input_table_with_pop, input_table_with_pop[[args$split_col]])

for (pop_index in names(input_table_with_pop_split)) {
    pop_table <- input_table_with_pop_split[[pop_index]]
    if (args$split_col %in% colnames(pop_table)) {
        pop_table <- pop_table %>% select(-all_of(args$split_col))
    }
    write_tsv(pop_table, paste0(args$output_directory, "/", pop_index, args$output_stub))
}

if(nrow(input_table_with_no_pop) > 0){
    output_unmapped_identifiers_output = ifelse(args$unmapped_identifiers_output == "",
        paste0(args$output_directory, "/", args$unmapped_identifiers_output), args$unmapped_identifiers_output)
    cat(unique(sort(input_table_with_no_pop[[args$identifier_col]])), sep = "\n", file = output_unmapped_identifiers_output)
}
