/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { softwareVersionsToYAML } from '../subworkflows/nf-core/utils_nfcore_pipeline'

include { TRANSLATE_LOCI_OF_INTEREST } from '../modules/local/translate_loci_of_interest'
include { SPLIT_AA_TABLE_BY_POP } from '../modules/local/split_aa_table_by_population'
include { SPLIT_ALLELE_TABLE_BY_POP } from '../modules/local/split_allele_table_by_population'
include { ESTIMATE_ALLELE_PREVALENCE_NAIVE } from '../modules/local/estimate_allele_prevalence_naive'
include { ESTIMATE_MLAF } from '../subworkflows/local/estimate_mlaf'
include { ESTIMATE_SLAF } from '../subworkflows/local/estimate_slaf'
include { MERGE_TABLES } from '../modules/local/merge_tables'
include { CONCAT_TABLES } from '../modules/local/concat_tables'
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow PLASMODIUMDRUGRES {
    take:
    allele_table
    panel_info_bed_with_ref
    loci_of_interest_bed
    translate_loci_extra_args
    population_assignment
    population_index_lookup
    mlaf_method
    loci_groups
    slaf_method
    ch_versions

    main:
    // Avoid gating on `population_map` directly: this is a channel handle and can be truthy
    // even when it's effectively "missing", causing downstream processes to receive null paths.
    // Instead, decide based on pipeline parameters used to construct `population_map`.
    def has_population_assignment = params.population_assignment || (params.pmo && params.pmo_population_fields)

    TRANSLATE_LOCI_OF_INTEREST(allele_table, panel_info_bed_with_ref, file(loci_of_interest_bed), translate_loci_extra_args)
    ch_versions = ch_versions.mix(TRANSLATE_LOCI_OF_INTEREST.out.versions)

    // Split allele table by population for mhaps_freq (only when population_map)
    if (slaf_method == "mhaps_freq" && has_population_assignment) {
        SPLIT_ALLELE_TABLE_BY_POP(allele_table, population_assignment)
        mhaps_allele_table_ch = (SPLIT_ALLELE_TABLE_BY_POP.out.per_pop_tables).flatten()
        ch_versions = ch_versions.mix(SPLIT_ALLELE_TABLE_BY_POP.out.versions)
    } else if (slaf_method == "mhaps_freq") {
        mhaps_allele_table_ch = allele_table
    } else {
        mhaps_allele_table_ch = channel.empty()
    }

    // Split amino acid table if population map is provided
    if (has_population_assignment) {
        SPLIT_AA_TABLE_BY_POP(TRANSLATE_LOCI_OF_INTEREST.out.collapsed_amino_acid_calls, population_assignment)
        aa_table_ch = (SPLIT_AA_TABLE_BY_POP.out.per_pop_tables).flatten()
        ch_versions = ch_versions.mix(SPLIT_AA_TABLE_BY_POP.out.versions)
    } else {
        aa_table_ch = TRANSLATE_LOCI_OF_INTEREST.out.collapsed_amino_acid_calls
    }

    // Estimate Single Locus Allele Prevalence
    ESTIMATE_ALLELE_PREVALENCE_NAIVE(aa_table_ch)
    ch_versions = ch_versions.mix(ESTIMATE_ALLELE_PREVALENCE_NAIVE.out.versions)

    // Estimate Multi Locus Allele Frequency (requires --loci_groups)
    if (loci_groups) {
        ESTIMATE_MLAF(mlaf_method, aa_table_ch, file(loci_groups))
        mlaf_output_ch = ESTIMATE_MLAF.out.mlaf_output
        sl_from_ml_output_ch = ESTIMATE_MLAF.out.sl_from_ml_output
        ch_versions = ch_versions.mix(ESTIMATE_MLAF.out.versions)
    } else {
        mlaf_output_ch = channel.empty()
        sl_from_ml_output_ch = channel.empty()
    }

    // Estimate Single Locus Allele Frequency. Select appropriate input channel based on slaf_method.
    slaf_method_input = slaf_method == "mhaps_freq" ? mhaps_allele_table_ch : aa_table_ch
    ESTIMATE_SLAF(
        slaf_method,
        slaf_method_input,
        slaf_method == "mhaps_freq" ? TRANSLATE_LOCI_OF_INTEREST.out.loci_of_interest_for_target_for_microhap : channel.empty()
    )
    slaf_output = ESTIMATE_SLAF.out.slaf_output
    ch_versions = ch_versions.mix(ESTIMATE_SLAF.out.versions)

    // -------------------------------------------------------------------------
    // Merge per-population outputs and concat into final summaries
    // -------------------------------------------------------------------------
    all_outputs = ESTIMATE_ALLELE_PREVALENCE_NAIVE.out.allele_prevalence.mix(
        mlaf_output_ch,
        sl_from_ml_output_ch,
        slaf_output)
    outputs_per_population = all_outputs.groupTuple()

    population_index_lookup_for_merge = has_population_assignment
        ? population_index_lookup.first()
        : channel.value(file("${projectDir}/assets/empty_population_index_lookup.tsv"))

    if (has_population_assignment) {
        MERGE_TABLES(outputs_per_population, population_index_lookup_for_merge)
    } else {
        updated_ch = outputs_per_population.map { _pop_index, files ->
            [params.population_label, files]
        }
        MERGE_TABLES(updated_ch, population_index_lookup_for_merge)
    }
    ch_versions = ch_versions.mix(MERGE_TABLES.out.versions)

    all_sl_summary_ch = MERGE_TABLES.out.sl_summary.collect()
    all_ml_summary_ch = MERGE_TABLES.out.ml_summary.collect()
    all_sl_from_ml_summary_ch = MERGE_TABLES.out.sl_from_ml_summary.collect()

    CONCAT_TABLES(all_sl_summary_ch, all_ml_summary_ch, all_sl_from_ml_summary_ch)
    ch_versions = ch_versions.mix(CONCAT_TABLES.out.versions)

    //
    // Collate and save software versions
    //
    softwareVersionsToYAML(ch_versions)
        .collectFile(
            storeDir: "${params.outdir}/pipeline_info",
            name: 'nf_core_plasmodiumdrugres_software_versions.yml',
            sort: true,
            newLine: true
        )

    emit:
    sl_summary     = CONCAT_TABLES.out.sl_summary
    ml_summary     = CONCAT_TABLES.out.ml_summary
    raw_summaries  = CONCAT_TABLES.out.raw_summaries
    versions       = ch_versions
}
