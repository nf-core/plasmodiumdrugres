/*
 * STEP - ESTIMATE_ALLELE_PREVALENCE_NAIVE
 * Estimate allele prevalence naively
 */

process ESTIMATE_ALLELE_PREVALENCE_NAIVE {
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'plasmogenepi/plasmodiumdrugres-pgecore-r:1.0.0' :
        'plasmogenepi/plasmodiumdrugres-pgecore-r:1.0.0' }"

    input:
    path aa_calls

    output:
    tuple val("${aa_calls.getBaseName(3)}"), path("${aa_calls.getBaseName(3)}.allele_prev.tsv"), emit: allele_prevalence
    path "versions.yml", emit: versions

    script:
    """
    Rscript ${projectDir}/bin/PGEcore/scripts/estimate_allele_prevalence_naive/estimate_allele_prevalence_naive.R \\
        --aa_calls ${aa_calls} \\
        --output "${aa_calls.getBaseName(3)}.allele_prev.tsv"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$( R --version | sed -n '1s/.*\\([0-9]\\+\\.[0-9]\\+\\.[0-9]\\+\\).*/\\1/p' )
    END_VERSIONS
    """
}
