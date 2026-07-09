/*
 * STEP - MERGE_TABLES
 * Compile outputs into final summaries
 */

process MERGE_TABLES {
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'plasmogenepi/plasmodiumdrugres-r-tidyverse:1.0.0' :
        'plasmogenepi/plasmodiumdrugres-r-tidyverse:1.0.0' }"

    input:
    tuple val(pop), path(pop_files)

    output:
    path "${pop}.sl_summary.tsv", emit: sl_summary
    path "${pop}.ml_summary.tsv", emit: ml_summary
    path "${pop}.sl_from_ml_summary.tsv", emit: sl_from_ml_summary
    path "versions.yml", emit: versions

    script:
    """
    slap_table=\$(ls ${pop_files} | grep 'prev')
    mlaf_table=\$(ls ${pop_files} | grep 'mlaf')
    slaf_table=\$(ls ${pop_files} | grep 'slaf')
    sl_from_ml_table=\$(ls ${pop_files} | grep 'sl_from_ml')

    Rscript ${projectDir}/bin/merge_tables.R --freq_table \${slaf_table} --population ${pop} --prev_table \${slap_table} --output ${pop}.sl_summary.tsv
    Rscript ${projectDir}/bin/add_population_column.R --table \${mlaf_table} --population ${pop} --output ${pop}.ml_summary.tsv
    Rscript ${projectDir}/bin/add_population_column.R --table \${sl_from_ml_table} --population ${pop} --output ${pop}.sl_from_ml_summary.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$( R --version | sed -n '1s/.*\\([0-9]\\+\\.[0-9]\\+\\.[0-9]\\+\\).*/\\1/p' )
    END_VERSIONS
    """
}
