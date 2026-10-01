/*
 * STEP - SPLIT_AA_TABLE_BY_POP
 * Split amino acid tables into seperate populations based on specimen_name
 */

process SPLIT_AA_TABLE_BY_POP {
    tag "${aa_table.name}"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
?         'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/13/13ebff194324bc29f494831d874c29068468ef584f909ef7578025288c8bee62/data'
:         'community.wave.seqera.io/library/tidyverse_tables:c07d709009059eb9' }"

    input:
    path aa_table
    path population_map

    output:
    path "*.collapsed_amino_acid_calls.tsv.gz", emit: per_pop_tables
    path "unmapped_specimens.txt", optional: true, emit: unmapped_report
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

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
        r-dplyr: \$( Rscript -e 'cat(as.character(packageVersion("dplyr")))' )
        r-readr: \$( Rscript -e 'cat(as.character(packageVersion("readr")))' )
        r-tibble: \$( Rscript -e 'cat(as.character(packageVersion("tibble")))' )
        r-optparse: \$( Rscript -e 'cat(as.character(packageVersion("optparse")))' )
    END_VERSIONS
    """
}
