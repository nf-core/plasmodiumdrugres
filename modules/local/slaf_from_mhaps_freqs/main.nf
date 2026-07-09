/*
 * STEP - SLAF_FROM_MHAPS_FREQS
 * Calculate single-locus allele frequencies from microhaplotype frequencies
 */

process SLAF_FROM_MHAPS_FREQS {
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'plasmogenepi/plasmodiumdrugres-pgecore-r:1.0.0' :
        'plasmogenepi/plasmodiumdrugres-pgecore-r:1.0.0' }"

    input:
    tuple val(group_name), path(mhaps_slaf_fnp)
    path loci_of_interest_per_microhaps_fnp

    output:
    tuple val("${group_name}"), path("${group_name}.slaf.tsv"), emit: slaf
    path "versions.yml", emit: versions

    script:
    """
    Rscript ${projectDir}/bin/PGEcore/scripts/calc_slaf_based_on_mhap_freqs/slaf_from_mhaps_freqs.R \\
        --mhaps_slaf_fnp ${mhaps_slaf_fnp} \\
        --loci_of_interest_per_microhaps_fnp ${loci_of_interest_per_microhaps_fnp} \\
        --slaf_output ${group_name}.slaf.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$( R --version | sed -n '1s/.*\\([0-9]\\+\\.[0-9]\\+\\.[0-9]\\+\\).*/\\1/p' )
    END_VERSIONS
    """
}
