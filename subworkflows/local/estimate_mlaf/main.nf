//
// Estimate multi locus allele frequencies using choice of tool/method
//

include { MLBM_WRAPPER } from '../../../modules/local/mlbm_wrapper'
include { FEM_WRAPPER } from '../../../modules/local/fem_wrapper'
include { ESTIMATE_ML_PREVFREQ_NAIVE } from '../../../modules/local/estimate_multilocus_prevfreq_naive'
include { SLAF_FROM_STAVE_MLAF as MLBM_SLAF_FROM_STAVE_MLAF} from '../../../modules/local/slaf_from_stave_mlaf'
include { SLAF_FROM_STAVE_MLAF as FEM_SLAF_FROM_STAVE_MLAF} from '../../../modules/local/slaf_from_stave_mlaf'

workflow ESTIMATE_MLAF {

    take:
    method
    amino_acid_calls
    loci_groups

    main:
    // TODO: add naive method (estimate_multilocus_prevfreq_naive) when groups are added in
    // TODO: These estimates should also include prev output
    // TODO: FEM needs to output population too
    ch_versions = channel.empty()
    if (method == "MLBM") {
        MLBM_WRAPPER(amino_acid_calls, loci_groups)
        mlaf_output = MLBM_WRAPPER.out.mlaf
        MLBM_SLAF_FROM_STAVE_MLAF(MLBM_WRAPPER.out.mlaf)
        sl_from_ml_output = MLBM_SLAF_FROM_STAVE_MLAF.out.slaf
        ch_versions = ch_versions.mix(MLBM_WRAPPER.out.versions).mix(MLBM_SLAF_FROM_STAVE_MLAF.out.versions)
    } else if (method == "FEM") {
        FEM_WRAPPER(amino_acid_calls, loci_groups)
        mlaf_output = FEM_WRAPPER.out.mlaf
        FEM_SLAF_FROM_STAVE_MLAF(FEM_WRAPPER.out.mlaf)
        sl_from_ml_output = FEM_SLAF_FROM_STAVE_MLAF.out.slaf
        ch_versions = ch_versions.mix(FEM_WRAPPER.out.versions).mix(FEM_SLAF_FROM_STAVE_MLAF.out.versions)
    }  else if (method == "naive") {
        ESTIMATE_ML_PREVFREQ_NAIVE(amino_acid_calls, loci_groups, params.naive_mlaf_method)
        mlaf_output = ESTIMATE_ML_PREVFREQ_NAIVE.out.mlaf
        sl_from_ml_output = ESTIMATE_ML_PREVFREQ_NAIVE.out.slaf_from_mlaf
        ch_versions = ch_versions.mix(ESTIMATE_ML_PREVFREQ_NAIVE.out.versions)
    } else {
        throw new IllegalArgumentException("Error: 'mlaf_method' must be one of ['MLBM','FEM','naive']. Provided value: ${method}.")
    }

    emit:
    mlaf_output = mlaf_output
    sl_from_ml_output = sl_from_ml_output
    versions = ch_versions
}
