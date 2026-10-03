/*
 * STEP - IDM_WRAPPER
 * Run the incomplete data model (IDM) wrapper script
 */

process IDM_WRAPPER {

    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
?         'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/09/095a76bcdad467aecddbf4109b65c1dc1ec1a624a30c19a0cf1c4e9aded6b604/data'
:         'community.wave.seqera.io/library/idm_wrapper:1a9e1a40d75bade3' }"

    input:
    path aa_calls_input

    output:
    tuple val("${aa_calls_input.getBaseName(3)}"), path("${aa_calls_input.getBaseName(3)}.aa_slaf.tsv"), emit: slaf
    path "versions.yml", emit: versions

    script:
    """
    export PATH="\$(Rscript -e 'cat(system.file(\"exec\", package = \"PGEcore\"))'):\${PATH}"
    IDM_wrapper \\
        --aa_calls ${aa_calls_input} \\
        --slaf_output "${aa_calls_input.getBaseName(3)}.aa_slaf.tsv"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$( R --version | sed -n '1s/.*\\([0-9]\\+\\.[0-9]\\+\\.[0-9]\\+\\).*/\\1/p' )
        r-pgecore: \$( Rscript -e 'cat(as.character(packageVersion("PGEcore")))' )
    END_VERSIONS
    """
}
