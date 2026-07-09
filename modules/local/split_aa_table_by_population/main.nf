/*
 * STEP - SPLIT_AA_TABLE_BY_POP
 * Split amino acid tables into separate populations based on specimen_name
 */

process SPLIT_AA_TABLE_BY_POP {
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'plasmogenepi/plasmodiumdrugres-r-tidyverse:1.0.0' :
        'plasmogenepi/plasmodiumdrugres-r-tidyverse:1.0.0' }"

    input:
    path aa_table
    path population_map

    output:
    path "*.collapsed_amino_acid_calls.tsv.gz", emit: per_pop_tables
    path "unmapped_specimens.txt", optional: true, emit: unmapped_report
    path "versions.yml", emit: versions

    script:
    """
    ${projectDir}/bin/split_table_by_population_map.R \\
        --input_table_fnp ${aa_table} \\
        --population_map ${population_map} \\
        --population_col population --identifier_col specimen_name \\
        --output_stub .collapsed_amino_acid_calls.tsv.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$( R --version | sed -n '1s/.*\\([0-9]\\+\\.[0-9]\\+\\.[0-9]\\+\\).*/\\1/p' )
    END_VERSIONS
    """
}
