/*
 * STEP - ESTIMATE_ALLELE_PREVALENCE_NAIVE
 * Estimate allele prevalence naively
 */

process ESTIMATE_ALLELE_PREVALENCE_NAIVE {
    tag "${aa_calls.name}"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
?         'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/8b/8bb7bd8a2b78f4d460b00f1df86ec9e05e68ae1cfb2132665575995df5404ce1/data'
:         'community.wave.seqera.io/library/pgecore:7027edf49864476b' }"

    input:
    path aa_calls

    output:
    tuple val("${aa_calls.getBaseName(3)}"), path("${aa_calls.getBaseName(3)}.allele_prev.tsv") , emit: allele_prevalence
    path "versions.yml"                                                                         , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    export PATH="\$(Rscript -e 'cat(system.file(\"exec\", package = \"PGEcore\"))'):\${PATH}"
    estimate_allele_prevalence_naive \\
        --aa_calls ${aa_calls} \\
        --output "${aa_calls.getBaseName(3)}.allele_prev.tsv"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$( R --version | sed -n '1s/.*\\([0-9]\\+\\.[0-9]\\+\\.[0-9]\\+\\).*/\\1/p' )
        r-pgecore: \$( Rscript -e 'cat(as.character(packageVersion("PGEcore")))' )
    END_VERSIONS
    """
}
