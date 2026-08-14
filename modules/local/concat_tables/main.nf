/*
 * STEP - CONCAT_TABLES
 * concatenate output tables
 */

process CONCAT_TABLES {

    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
?         'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/25/25ec37d72caff047524cad028f190afbd7e97ff61cba29d8172883993c8a5c75/data'
:         'community.wave.seqera.io/library/r_tidyverse:4e1e0dec2f11d009' }"

    input:
    path sl_files
    path ml_files
    path sl_from_ml_files

    output:
    path "sl_summary.tsv", emit: sl_summary
    path "ml_summary.tsv", emit: ml_summary
    path "raw_summaries", emit: raw_summaries
    path "versions.yml", emit: versions

    script:
    """
    # Concatenate deterministically using R (avoids shell header/ordering drift).
    Rscript ${projectDir}/bin/concat_tables.R \
        --sl-files "${sl_files.join(',')}" \
        --ml-files "${ml_files.join(',')}" \
        --sl-from-ml-files "${sl_from_ml_files.join(',')}" \
        --sl-out "sl_summary.tsv" \
        --ml-out "ml_summary.tsv" \
        --raw-out-dir "raw_summaries"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$( R --version | sed -n '1s/.*\\([0-9]\\+\\.[0-9]\\+\\.[0-9]\\+\\).*/\\1/p' )
    END_VERSIONS
    """
}
