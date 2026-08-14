/*
 * STEP - SPLIT_AA_TABLE_BY_POP
 * Split amino acid tables into seperate populations based on specimen_name
 */

process SPLIT_AA_TABLE_BY_POP {
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
?         'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/25/25ec37d72caff047524cad028f190afbd7e97ff61cba29d8172883993c8a5c75/data'
:         'community.wave.seqera.io/library/r_tidyverse:4e1e0dec2f11d009' }"

    input:
    path aa_table
    path population_map

    output:
    path "*.collapsed_amino_acid_calls.tsv.gz", emit: per_pop_tables
    path "unmapped_specimens.txt", optional: true, emit: unmapped_report
    path "versions.yml", emit: versions

    script:
    """
     ${projectDir}/bin/split_table_by_population_map.R \
            --input_table_fnp ${aa_table} \
            --population_map ${population_map} \
            --split_col population_index --identifier_col specimen_name \
            --output_stub .collapsed_amino_acid_calls.tsv.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$( R --version | sed -n '1s/.*\\([0-9]\\+\\.[0-9]\\+\\.[0-9]\\+\\).*/\\1/p' )
    END_VERSIONS
    """
}
