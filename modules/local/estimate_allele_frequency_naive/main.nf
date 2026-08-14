/*
 * STEP - ESTIMATE_ALLELE_FREQUENCY_NAIVE
 * Estimate allele frequencies naively by read_count_prop or presence_absence
 */

process ESTIMATE_ALLELE_FREQUENCY_NAIVE {

    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
?         'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/b8/b8b5976e182bb3b8f3b3073fe7ccb663bfa240ef8476d59faf2cccf8b180fe6f/data'
:         'community.wave.seqera.io/library/pgecore_r:b3d363b44f3cab5e' }"

    input:
    path aa_calls
    val method

    output:
    tuple val("${aa_calls.getBaseName(3)}"), path("${aa_calls.getBaseName(3)}.aa_slaf.tsv"), emit: slaf
    path "versions.yml", emit: versions

    script:
    """
    Rscript ${projectDir}/bin/PGEcore/scripts/estimate_allele_frequency_naive/estimate_allele_frequency_naive.R \
        --aa_calls ${aa_calls} \
        --method ${method} \
        --output "${aa_calls.getBaseName(3)}.aa_slaf.tsv"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$( R --version | sed -n '1s/.*\\([0-9]\\+\\.[0-9]\\+\\.[0-9]\\+\\).*/\\1/p' )
    END_VERSIONS
    """
}
