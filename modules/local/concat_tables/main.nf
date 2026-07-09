/*
 * STEP - CONCAT_TABLES
 * Concatenate output tables
 */

process CONCAT_TABLES {
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'plasmogenepi/plasmodiumdrugres-r-tidyverse:1.0.0' :
        'plasmogenepi/plasmodiumdrugres-r-tidyverse:1.0.0' }"

    publishDir "${params.outdir}", mode: 'copy', overwrite: true

    input:
    path sl_files
    path ml_files
    path sl_from_ml_files

    output:
    path "sl_summary.tsv", emit: sl_summary
    path "ml_summary.tsv", emit: ml_summary
    path "sl_from_ml_summary.tsv", emit: sl_from_ml_summary
    path "versions.yml", emit: versions

    script:
    """
    Rscript ${projectDir}/bin/concat_tables.R \\
        --sl-files "${sl_files.join(',')}" \\
        --ml-files "${ml_files.join(',')}" \\
        --sl-from-ml-files "${sl_from_ml_files.join(',')}" \\
        --sl-out "sl_summary.tsv" \\
        --ml-out "ml_summary.tsv" \\
        --sl-from-ml-out "sl_from_ml_summary.tsv"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$( R --version | sed -n '1s/.*\\([0-9]\\+\\.[0-9]\\+\\.[0-9]\\+\\).*/\\1/p' )
    END_VERSIONS
    """
}
