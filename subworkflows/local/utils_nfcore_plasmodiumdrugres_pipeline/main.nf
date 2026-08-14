//
// Subworkflow with functionality specific to the nf-core/plasmodiumdrugres pipeline
//

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT FUNCTIONS / MODULES / SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { UTILS_NFSCHEMA_PLUGIN     } from '../../nf-core/utils_nfschema_plugin'
include { paramsSummaryMap          } from 'plugin/nf-schema'
include { completionEmail           } from '../../nf-core/utils_nfcore_pipeline'
include { completionSummary         } from '../../nf-core/utils_nfcore_pipeline'
include { UTILS_NFCORE_PIPELINE     } from '../../nf-core/utils_nfcore_pipeline'
include { UTILS_NEXTFLOW_PIPELINE   } from '../../nf-core/utils_nextflow_pipeline'
include { EXTRACT_ALLELE_TABLE      } from '../../../modules/local/extract_allele_table'
include { EXTRACT_BED_FILE_FROM_PMO } from '../../../subworkflows/local/generate_reference_bed_file'
include { EXTRACT_POPULATION_MAP_FROM_PMO } from '../../../modules/local/extract_population_map_from_pmo'
include { INDEX_POPULATION_ASSIGNMENT } from '../../../modules/local/index_population_assignment'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    SUBWORKFLOW TO INITIALISE PIPELINE
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow PIPELINE_INITIALISATION {

    take:
    version           // boolean: Display version and exit
    validate_params   // boolean: Boolean whether to validate parameters against the schema at runtime
    monochrome_logs   // boolean: Do not use coloured log outputs
    nextflow_cli_args //  array: List of positional nextflow CLI args
    outdir            //  string: The output directory where the results will be saved
    help              // boolean: Display help message and exit
    help_full         // boolean: Show the full help message
    show_hidden       // boolean: Show hidden parameters in the help message

    main:

    ch_versions = channel.empty()

    //
    // Print version and exit if required and dump pipeline parameters to JSON file
    //
    UTILS_NEXTFLOW_PIPELINE (
        version,
        true,
        outdir,
        workflow.profile.tokenize(',').intersect(['conda', 'mamba']).size() >= 1
    )

    //
    // Validate parameters and generate parameter summary to stdout
    //
    before_text = """
-\033[2m----------------------------------------------------\033[0m-
                                        \033[0;32m,--.\033[0;30m/\033[0;32m,-.\033[0m
\033[0;34m        ___     __   __   __   ___     \033[0;32m/,-._.--~\'\033[0m
\033[0;34m  |\\ | |__  __ /  ` /  \\ |__) |__         \033[0;33m}  {\033[0m
\033[0;34m  | \\| |       \\__, \\__/ |  \\ |___     \033[0;32m\\`-._,-`-,\033[0m
                                        \033[0;32m`._,._,\'\033[0m
\033[0;35m  nf-core/plasmodiumdrugres ${workflow.manifest.version}\033[0m
-\033[2m----------------------------------------------------\033[0m-
"""
    after_text = """${workflow.manifest.doi ? "\n* The pipeline\n" : ""}${workflow.manifest.doi.tokenize(",").collect { doi -> "    https://doi.org/${doi.trim().replace('https://doi.org/','')}"}.join("\n")}${workflow.manifest.doi ? "\n" : ""}
* The nf-core framework
    https://doi.org/10.1038/s41587-020-0439-x

* Software dependencies
    https://github.com/nf-core/plasmodiumdrugres/blob/master/CITATIONS.md
"""
    if (monochrome_logs) {
        before_text = before_text.replaceAll(/\033\[[0-9;]*m/, '')
    }

    command = "nextflow run ${workflow.manifest.name} -profile <docker/singularity/.../institute> --pmo input.pmo.json --loci_of_interest_bed loci_of_interest.bed --loci_groups loci_groups.tsv --outdir <OUTDIR>"

    UTILS_NFSCHEMA_PLUGIN (
        workflow,
        validate_params,
        null,
        help,
        help_full,
        show_hidden,
        before_text,
        after_text,
        command,
        false
    )

    //
    // Check config provided to the pipeline
    //
    UTILS_NFCORE_PIPELINE (
        nextflow_cli_args
    )

    //
    // Custom validation for pipeline parameters
    //
    validateInputParameters()

    //
    // Create allele table input for pipeline
    //
    // TODO: add option to split pmo and then run it in chunks
    def ref_type = params.targeted_reference ? "targeted_reference" :
        params.genome_reference ? "genome_reference" : "none"
    def fasta = params.targeted_reference ?: params.genome_reference ?: ""
    // Normalise PMO population fields:
    // - user provides comma-separated list, e.g. "collection_country, collection_date"
    // - python expects space-separated args for argparse `nargs='+'`.
    def pmo_population_fields_norm = null
    if (params.pmo_population_fields) {
        def raw = params.pmo_population_fields
        def fields = []
        if (raw instanceof List) {
            fields = raw.collect { field -> field?.toString() ?: '' }
        } else {
            fields = raw.toString().split(',') as List
        }
        fields = fields.collect { field -> field.trim() }.findAll { field -> field }
        // Join with spaces so the shell splits into multiple `--fields` arguments.
        pmo_population_fields_norm = fields.join(' ')
    }
    // Initialise channels for all branches to avoid unbound variables
    // Note: avoid `def` here so Nextflow can statically detect these
    // variables for the `emit:` block.
    allele_table_ch = channel.empty()
    panel_info_bed_ch = channel.empty()
    raw_population_assignment_ch = null
    if (params.pmo) {
        def pmo_ch = channel.fromPath(params.pmo, checkIfExists: true)
        EXTRACT_ALLELE_TABLE(pmo_ch)
        allele_table_ch = EXTRACT_ALLELE_TABLE.out.allele_table
        ch_versions = ch_versions.mix(EXTRACT_ALLELE_TABLE.out.versions)
        EXTRACT_BED_FILE_FROM_PMO(pmo_ch, ref_type, fasta)
        panel_info_bed_ch = EXTRACT_BED_FILE_FROM_PMO.out.panel_info_bed
        ch_versions = ch_versions.mix(EXTRACT_BED_FILE_FROM_PMO.out.versions)
        if (params.population_assignment) {
            raw_population_assignment_ch = channel.fromPath(params.population_assignment, checkIfExists: true)
        } else if (pmo_population_fields_norm) {
            EXTRACT_POPULATION_MAP_FROM_PMO(pmo_ch, pmo_population_fields_norm, params.pmo_population_separator)
            raw_population_assignment_ch = EXTRACT_POPULATION_MAP_FROM_PMO.out.population_map
            ch_versions = ch_versions.mix(EXTRACT_POPULATION_MAP_FROM_PMO.out.versions)
        }
    } else if (params.allele_table) {
        allele_table_ch = channel.fromPath(params.allele_table, checkIfExists: true)
        panel_info_bed_ch = channel.fromPath(params.panel_info_bed, checkIfExists: true)
        if (params.population_assignment) {
            raw_population_assignment_ch = channel.fromPath(params.population_assignment, checkIfExists: true)
        }
    }

    population_assignment_ch = null
    population_index_lookup_ch = null
    if (raw_population_assignment_ch) {
        INDEX_POPULATION_ASSIGNMENT(raw_population_assignment_ch)
        population_assignment_ch = INDEX_POPULATION_ASSIGNMENT.out.population_map_indexed
        population_index_lookup_ch = INDEX_POPULATION_ASSIGNMENT.out.population_index_lookup
        ch_versions = ch_versions.mix(INDEX_POPULATION_ASSIGNMENT.out.versions)
    }

    emit:
    allele_table_ch    = allele_table_ch
    panel_info_bed_ch  = panel_info_bed_ch
    population_assignment_ch  = population_assignment_ch
    population_index_lookup_ch = population_index_lookup_ch
    versions        = ch_versions
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    SUBWORKFLOW FOR PIPELINE COMPLETION
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow PIPELINE_COMPLETION {

    take:
    email           //  string: email address
    email_on_fail   //  string: email address sent on pipeline failure
    plaintext_email // boolean: Send plain-text email instead of HTML
    outdir          //    path: Path to output directory where results will be published
    monochrome_logs // boolean: Disable ANSI colour codes in log output

    main:
    summary_params = paramsSummaryMap(workflow, parameters_schema: "nextflow_schema.json")

    //
    // Completion email and summary
    //
    workflow.onComplete {
        if (email || email_on_fail) {
            completionEmail(
                summary_params,
                email,
                email_on_fail,
                plaintext_email,
                outdir,
                monochrome_logs,
            )
        }

        completionSummary(monochrome_logs)
    }

    workflow.onError {
        log.error "Pipeline failed. Please refer to troubleshooting docs for common issues: https://nf-co.re/docs/running/troubleshooting"
    }
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
//
// Check and validate pipeline parameters
//
def validateInputParameters() {
    // Collect validation errors
    def validation_errors = []
    def validation_warnings = []

    // Ensure only one of `pmo` or `allele_table` is set
    if (params.pmo && params.allele_table) {
        validation_errors.add("Only one of 'pmo' or 'allele_table' can be set, but not both.")
    }
    if (params.pmo_population_fields && params.population_assignment) {
        validation_warnings.add("WARNING: Both 'pmo_population_fields' and 'population_assignment' set, 'population_assignment' will be used.")
    }
    if (params.pmo) {
        if (params.genome_reference && params.targeted_reference) {
            validation_warnings.add("WARNING: Both 'genome_reference' or 'targeted_reference' set, 'targeted_reference' will be used.")
        }
    } else if (params.allele_table) {
        if (!params.panel_info_bed) {
            validation_errors.add("Missing required parameter: '--panel_info_bed' is not set and is required with --allele_table.")
        }
        if (params.genome_reference || params.targeted_reference) {
            validation_warnings.add("WARNING: Either 'genome_reference' or 'targeted_reference' set, but neither will be used.")
        }
        if (params.pmo_population_fields) {
            validation_warnings.add("WARNING: 'pmo_population_fields' set with '--allele_table'. '--pmo_population_fields' is only used for PMO input and will be ignored.")
        }
    } else {
        validation_errors.add("Missing required parameter: Either '--pmo' or '--allele_table' must be set, but neither were.")
    }

    // Warn if both population_assignment and population_label is set
    if ((params.population_assignment) && (params.population_label!='pop1')) {
        validation_warnings.add("WARNING: both '--population_assignment' and --'population_label' set. '--population_assignment' will be used.")
    }

    // Check required files and validate optional files when provided
    if (!params.loci_of_interest_bed) {
        validation_errors.add("Missing required file parameter: 'loci_of_interest_bed' is not set.")
    } else if (!file(params.loci_of_interest_bed).exists()) {
        validation_errors.add("File not found: 'loci_of_interest_bed' at path '${params.loci_of_interest_bed}'.")
    }

    if (params.loci_groups && !file(params.loci_groups).exists()) {
        validation_errors.add("File not found: 'loci_groups' at path '${params.loci_groups}'.")
    }

    // Print warnings if any
    if (validation_warnings.size() > 0) {
        log.warn "Input validation warnings:\n" +
            validation_warnings.collect { warning -> "- ${warning}" }.join("\n")
    }

    // Report all errors at once
    if (validation_errors.size() > 0) {
        log.error "Input validation failed with the following errors:\n" +
            validation_errors.collect { error -> "- ${error}" }.join("\n")
        exit 1
    }

    log.info "All input validations passed successfully."
}
