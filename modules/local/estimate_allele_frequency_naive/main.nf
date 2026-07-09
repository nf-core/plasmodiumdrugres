/*
 * STEP - ESTIMATE_ALLELE_FREQUENCY_NAIVE
 * Estimate allele frequencies naively by read_count_prop or presence_absence
 */

process ESTIMATE_ALLELE_FREQUENCY_NAIVE {
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'plasmogenepi/plasmodiumdrugres-pgecore-r:1.0.0' :
        'plasmogenepi/plasmodiumdrugres-pgecore-r:1.0.0' }"

    input:
    path aa_calls
    val method

    output:
    tuple val("${aa_calls.getBaseName(3)}"), path("${aa_calls.getBaseName(3)}.aa_slaf.tsv"), emit: slaf
    path "versions.yml", emit: versions

    script:
    """
    Rscript ${projectDir}/bin/PGEcore/scripts/estimate_allele_frequency_naive/estimate_allele_frequency_naive.R \\
        --aa_calls ${aa_calls} \\
        --method ${method} \\
        --output "${aa_calls.getBaseName(3)}.aa_slaf.tsv"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$( R --version | sed -n '1s/.*\\([0-9]\\+\\.[0-9]\\+\\.[0-9]\\+\\).*/\\1/p' )
    END_VERSIONS
    """
}
