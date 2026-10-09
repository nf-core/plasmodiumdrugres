/*
 * STEP - ESTIMATE_ML_PREVFREQ_NAIVE
 * Estimate multilocus prev/freq naively
 */

process ESTIMATE_ML_PREVFREQ_NAIVE {
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
?         'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/7b/7b7ca5eb26f1bbaf3fba4ea585e789071aa49902df3182030df649f596ac97b1/data'
:         'community.wave.seqera.io/library/pgecore:e9024a6dc6e9a694' }"

    input:
    path aa_calls
    path loci_groups
    val method

    output:
    tuple val("${aa_calls.getBaseName(3)}"), path("${aa_calls.getBaseName(3)}.aa_mlaf.tsv")       , emit: mlaf
    tuple val("${aa_calls.getBaseName(3)}"), path("${aa_calls.getBaseName(3)}.aa_sl_from_ml.tsv") , emit: slaf_from_mlaf
    path "versions.yml"                                                                           , emit: versions

    script:
    def extra_args = task.ext.args ? task.ext.args : ''

    """
    export PATH="\$(Rscript -e 'cat(system.file(\"exec\", package = \"PGEcore\"))'):\${PATH}"
    multilocus_prevfreq_naive \\
        --aa_calls $aa_calls \\
        --loci_groups $loci_groups \\
        --output "${aa_calls.getBaseName(3)}.aa_mlaf.tsv" \\
        --single_locus_output "${aa_calls.getBaseName(3)}.aa_sl_from_ml.tsv" \\
        --method ${method} \\
        ${extra_args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$( R --version | sed -n '1s/.*\\([0-9]\\+\\.[0-9]\\+\\.[0-9]\\+\\).*/\\1/p' )
        r-pgecore: \$( Rscript -e 'cat(as.character(packageVersion("PGEcore")))' )
    END_VERSIONS
    """
}
