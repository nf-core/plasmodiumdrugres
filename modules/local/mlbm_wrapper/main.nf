/*
 * STEP - MLBM_WRAPPER
 * Run the MultiLociBiallelicModel (MLBM) wrapper script
 */

process MLBM_WRAPPER {

    tag "${aa_calls.name}"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
?         'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/b2/b2cde7b1f98319441058490837b4fd366e55f570bf00c855d226e24c142595dd/data'
:         'community.wave.seqera.io/library/mlbm_wrapper:f62633294b5f1f53' }"

    input:
    path aa_calls
    path loci_group_table

    output:
    tuple val("${aa_calls.getBaseName(3)}"), path("${aa_calls.getBaseName(3)}.aa_mlaf.tsv"), emit: mlaf
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def extra_args = task.ext.args ? task.ext.args : ''

    """
    export PATH="\$(Rscript -e 'cat(system.file(\"exec\", package = \"PGEcore\"))'):\${PATH}"
    MultiLociBiallelicModel_wrapper \\
        --aa_calls ${aa_calls} \\
        --loci_groups ${loci_group_table} \\
        --mlaf_output "${aa_calls.getBaseName(3)}.aa_mlaf.tsv" \\
        ${extra_args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$( R --version | sed -n '1s/.*\\([0-9]\\+\\.[0-9]\\+\\.[0-9]\\+\\).*/\\1/p' )
        r-pgecore: \$( Rscript -e 'cat(as.character(packageVersion("PGEcore")))' )
        variantstring: \$( Rscript -e 'cat(as.character(packageVersion("variantstring")))' )
    END_VERSIONS
    """
}
