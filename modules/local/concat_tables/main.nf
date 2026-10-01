/*
 * STEP - CONCAT_TABLES
 * concatenate output tables
 */

process CONCAT_TABLES {

    tag "all populations"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
?         'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/13/13ebff194324bc29f494831d874c29068468ef584f909ef7578025288c8bee62/data'
:         'community.wave.seqera.io/library/tidyverse_tables:c07d709009059eb9' }"

    input:
    path sl_files
    path ml_files
    path sl_from_ml_files

    output:
    path "sl_summary.tsv", emit: sl_summary
    path "ml_summary.tsv", emit: ml_summary
    path "raw_summaries", emit: raw_summaries
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

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
        r-dplyr: \$( Rscript -e 'cat(as.character(packageVersion("dplyr")))' )
        r-readr: \$( Rscript -e 'cat(as.character(packageVersion("readr")))' )
        r-optparse: \$( Rscript -e 'cat(as.character(packageVersion("optparse")))' )
    END_VERSIONS
    """
}
