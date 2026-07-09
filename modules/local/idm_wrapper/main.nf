/*
 * STEP - IDM_WRAPPER
 * Run the incomplete data model (IDM) wrapper script
 */

process IDM_WRAPPER {
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'plasmogenepi/plasmodiumdrugres-idm:1.0.0' :
        'plasmogenepi/plasmodiumdrugres-idm:1.0.0' }"

    input:
    path aa_calls_input

    output:
    tuple val("${aa_calls_input.getBaseName(3)}"), path("${aa_calls_input.getBaseName(3)}.aa_slaf.tsv"), emit: slaf
    path "versions.yml", emit: versions

    script:
    """
    Rscript ${projectDir}/bin/PGEcore/scripts/IDM_wrapper/IDM_wrapper.R \\
        --aa_calls_input ${aa_calls_input} --slaf_output "${aa_calls_input.getBaseName(3)}.aa_slaf.tsv"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$( R --version | sed -n '1s/.*\\([0-9]\\+\\.[0-9]\\+\\.[0-9]\\+\\).*/\\1/p' )
    END_VERSIONS
    """
}
