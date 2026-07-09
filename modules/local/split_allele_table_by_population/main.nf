/*
 * STEP - SPLIT_ALLELE_TABLE_BY_POP
 * Split allele tables into separate populations based on specimen_name
 */

process SPLIT_ALLELE_TABLE_BY_POP {
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'plasmogenepi/plasmodiumdrugres-r-tidyverse:1.0.0' :
        'plasmogenepi/plasmodiumdrugres-r-tidyverse:1.0.0' }"

    input:
    path allele_table
    path population_map

    output:
    path "*.allele_table.tsv.gz", emit: per_pop_tables
    path "unmapped_identifers.txt", optional: true, emit: unmapped_report
    path "versions.yml", emit: versions

    script:
    """
    ${projectDir}/bin/split_table_by_population_map.R \\
        --input_table_fnp ${allele_table} \\
        --population_map ${population_map} \\
        --population_col population --identifier_col specimen_name \\
        --output_stub .allele_table.tsv.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$( R --version | sed -n '1s/.*\\([0-9]\\+\\.[0-9]\\+\\.[0-9]\\+\\).*/\\1/p' )
    END_VERSIONS
    """
}
