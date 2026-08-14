/*
 * STEP - MERGE_TABLES
 * Compile outputs into final summaries
 */

process MERGE_TABLES {

    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
?         'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/25/25ec37d72caff047524cad028f190afbd7e97ff61cba29d8172883993c8a5c75/data'
:         'community.wave.seqera.io/library/r_tidyverse:4e1e0dec2f11d009' }"

    input:
    tuple val(pop_index), path(pop_files)
    path population_index_lookup

    output:
    path "${pop_index}.sl_summary.tsv", emit: sl_summary
    path "${pop_index}.ml_summary.tsv", emit: ml_summary
    path "${pop_index}.sl_from_ml_summary.tsv", emit: sl_from_ml_summary
    path "versions.yml", emit: versions

    script:
    """
    if [ -s ${population_index_lookup} ]; then
        true_population=\$(awk -F'\\t' -v idx="${pop_index}" '\$1==idx {print \$2; exit}' ${population_index_lookup})
    else
        true_population="${pop_index}"
    fi

    # Match published estimate suffixes explicitly (avoid substring greps like 'prev'/'slaf').
    slap_table=\$(ls ${pop_files} | grep -E 'allele_prev\\.tsv\$')
    slaf_table=\$(ls ${pop_files} | grep -E 'aa_slaf\\.tsv\$' || ls ${pop_files} | grep -E '\\.slaf\\.tsv\$' | grep -v 'mhaps_slaf')
    mlaf_table=\$(ls ${pop_files} | grep -E 'aa_mlaf\\.tsv\$' || true)
    # Matches pipeline outputs (*.aa_sl_from_ml.tsv) and nf-test fixtures (sl_from_ml.tsv).
    sl_from_ml_table=\$(ls ${pop_files} | grep -E 'sl_from_ml\\.tsv\$' || true)

    Rscript ${projectDir}/bin/merge_tables.R --freq_table \${slaf_table} --population "\${true_population}" --prev_table \${slap_table} --output ${pop_index}.sl_summary.tsv
    if [ -n "\${mlaf_table}" ]; then
        Rscript ${projectDir}/bin/add_population_column.R --table \${mlaf_table} --population "\${true_population}" --output ${pop_index}.ml_summary.tsv
    else
        printf 'population\\tgroup_id\\tvariant\\tfreq\\n' > ${pop_index}.ml_summary.tsv
    fi
    if [ -n "\${sl_from_ml_table}" ]; then
        Rscript ${projectDir}/bin/add_population_column.R --table \${sl_from_ml_table} --population "\${true_population}" --output ${pop_index}.sl_from_ml_summary.tsv
    else
        printf 'population\\tgroup_id\\tvariant\\tsample_total\\tallele_total\\tallele_count\\tsample_count\\tfreq\\tprev\\n' > ${pop_index}.sl_from_ml_summary.tsv
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$( R --version | sed -n '1s/.*\\([0-9]\\+\\.[0-9]\\+\\.[0-9]\\+\\).*/\\1/p' )
    END_VERSIONS
    """
}
