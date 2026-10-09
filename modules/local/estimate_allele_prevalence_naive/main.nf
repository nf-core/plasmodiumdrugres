/*
 * STEP - ESTIMATE_ALLELE_PREVALENCE_NAIVE
 * Estimate allele prevalence naively
 */

process ESTIMATE_ALLELE_PREVALENCE_NAIVE {
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
?         'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/7b/7b7ca5eb26f1bbaf3fba4ea585e789071aa49902df3182030df649f596ac97b1/data'
:         'community.wave.seqera.io/library/pgecore:e9024a6dc6e9a694' }"

    input:
    path aa_calls

    output:
    tuple val("${aa_calls.getBaseName(3)}"), path("${aa_calls.getBaseName(3)}.allele_prev.tsv") , emit: allele_prevalence
    path "versions.yml"                                                                         , emit: versions

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
