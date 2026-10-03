//
// Generate reference bed file depending on input params
//

include { EXTRACT_PANEL_INFO_TO_BED } from '../../../modules/local/extract_panel_info_to_bed'
include { ADD_REF_SEQS_WITH_TARGETED_REF_FASTA } from '../../../modules/local/add_ref_seqs_with_targeted_ref_fasta'
include { ADD_REF_SEQS_WITH_FULL_GENOME_REF_FASTA } from '../../../modules/local/add_ref_seqs_with_full_genome_ref_fasta'

workflow EXTRACT_BED_FILE_FROM_PMO {

    take:
    pmo
    ref_type
    fasta

    main:

    ch_versions = channel.empty()
    EXTRACT_PANEL_INFO_TO_BED(pmo, ref_type == "none" ? "TRUE" : "FALSE")
    ch_versions = ch_versions.mix(EXTRACT_PANEL_INFO_TO_BED.out.versions)
    if (ref_type == "targeted_reference") {
        ADD_REF_SEQS_WITH_TARGETED_REF_FASTA(EXTRACT_PANEL_INFO_TO_BED.out.panel_info_bed, fasta)
        panel_info_bed = ADD_REF_SEQS_WITH_TARGETED_REF_FASTA.out.ref_bed_with_seqs
        ch_versions = ch_versions.mix(ADD_REF_SEQS_WITH_TARGETED_REF_FASTA.out.versions)
    } else if (ref_type == "genome_reference") {
        ADD_REF_SEQS_WITH_FULL_GENOME_REF_FASTA(EXTRACT_PANEL_INFO_TO_BED.out.panel_info_bed, fasta)
        panel_info_bed = ADD_REF_SEQS_WITH_FULL_GENOME_REF_FASTA.out.ref_bed_with_seqs
        ch_versions = ch_versions.mix(ADD_REF_SEQS_WITH_FULL_GENOME_REF_FASTA.out.versions)
    } else {
        panel_info_bed = EXTRACT_PANEL_INFO_TO_BED.out.panel_info_bed
    }

    emit:
    panel_info_bed = panel_info_bed
    versions = ch_versions
}
