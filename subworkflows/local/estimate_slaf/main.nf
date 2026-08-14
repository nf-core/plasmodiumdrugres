//
// Estimate single locus allele frequency using choice of tool/method
// From AA table: IDM, naive. From allele table: mhaps_freq (DCIFER → SLAF_FROM_MHAPS_FREQS).
//

include { IDM_WRAPPER } from '../../../modules/local/idm_wrapper'
include { ESTIMATE_ALLELE_FREQUENCY_NAIVE } from '../../../modules/local/estimate_allele_frequency_naive'
include { DCIFER_SLAF_WRAPPER } from '../../../modules/local/dcifer_slaf_wrapper'
include { SLAF_FROM_MHAPS_FREQS } from '../../../modules/local/slaf_from_mhaps_freqs'

workflow ESTIMATE_SLAF {

    take:
    method
    method_input         // allele table for mhaps_freq; AA table for other methods
    loci_of_interest_for_target_for_microhap  // for mhaps_freq only (pass channel.empty() for other methods)

    main:
    ch_versions = channel.empty()
    if (method == "IDM") {
        IDM_WRAPPER(method_input)
        slaf_output = IDM_WRAPPER.out.slaf
        ch_versions = ch_versions.mix(IDM_WRAPPER.out.versions)
    } else if (method == "naive") {
        ESTIMATE_ALLELE_FREQUENCY_NAIVE(method_input, params.naive_slaf_method)
        slaf_output = ESTIMATE_ALLELE_FREQUENCY_NAIVE.out.slaf
        ch_versions = ch_versions.mix(ESTIMATE_ALLELE_FREQUENCY_NAIVE.out.versions)
    } else if (method == "mhaps_freq") {
        DCIFER_SLAF_WRAPPER(method_input)
        mhaps_dcifer_ch = DCIFER_SLAF_WRAPPER.out.mhaps_slaf
        // Use .first() so the single loci file broadcasts to each mhaps_dcifer item (runs per population)
        SLAF_FROM_MHAPS_FREQS(mhaps_dcifer_ch, loci_of_interest_for_target_for_microhap.first())
        slaf_output_raw = SLAF_FROM_MHAPS_FREQS.out.slaf
        // No population_assignment: use "collapsed_amino_acid_calls" as group_name for merge consistency
        slaf_output = params.population_assignment
            ? slaf_output_raw
            : slaf_output_raw.map { _group_name, slaf_file ->
                ["collapsed_amino_acid_calls", slaf_file]
            }
        ch_versions = ch_versions.mix(DCIFER_SLAF_WRAPPER.out.versions).mix(SLAF_FROM_MHAPS_FREQS.out.versions)
    } else {
        throw new IllegalArgumentException("Error: 'slaf_method' must be one of ['IDM','naive','mhaps_freq']. Provided value: ${method}.")
    }

    emit:
    slaf_output = slaf_output
    versions = ch_versions
}
