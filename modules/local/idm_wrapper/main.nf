/*
 * STEP - IDM_WRAPPER
 * Run the incomplete data model (IDM) wrapper script
 */

process IDM_WRAPPER {

    tag "${aa_calls_input.name}"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
?         'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/8d/8d36c36eac2443da4ffe45914b55136b2b4f0ffa444bb7dc3c1ce8cd7065525f/data'
:         'community.wave.seqera.io/library/idm_wrapper:8fffb8098c99385c' }"

    input:
    path aa_calls_input

    output:
    tuple val("${aa_calls_input.getBaseName(3)}"), path("${aa_calls_input.getBaseName(3)}.aa_slaf.tsv"), emit: slaf
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

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
