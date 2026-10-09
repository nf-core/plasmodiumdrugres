/*
 * STEP - SPLIT_ALLELE_TABLE_BY_POP
 * Split allele tables into seperate populations based on specimen_name
 */

process SPLIT_ALLELE_TABLE_BY_POP {
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
?         'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/25/25ec37d72caff047524cad028f190afbd7e97ff61cba29d8172883993c8a5c75/data'
:         'community.wave.seqera.io/library/r_tidyverse:7733a7ba430c76e1' }"

    input:
    path allele_table
    path population_map

    output:
    path "*.allele_table.tsv.gz"    , emit: per_pop_tables
    path "unassigned_specimens.txt" , optional: true, emit: unassigned_report
    path "versions.yml"             , emit: versions

    script:
    """

    ${projectDir}/bin/split_table_by_population_map.R \
            --input_table_fnp ${allele_table} \
            --population_map ${population_map} \
            --split_col population_index --identifier_col specimen_name \
            --output_stub .allele_table.tsv.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$( R --version | sed -n '1s/.*\\([0-9]\\+\\.[0-9]\\+\\.[0-9]\\+\\).*/\\1/p' )
    END_VERSIONS
    """
}
