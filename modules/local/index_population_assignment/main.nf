/*
 * STEP - INDEX_POPULATION_ASSIGNMENT
 * Add stable internal indices to population assignment labels
 */

process INDEX_POPULATION_ASSIGNMENT {

    tag "${population_map.name}"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
?         'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/13/13ebff194324bc29f494831d874c29068468ef584f909ef7578025288c8bee62/data'
:         'community.wave.seqera.io/library/tidyverse_tables:c07d709009059eb9' }"

    input:
    path population_map

    output:
    path "population_map_indexed.tsv", emit: population_map_indexed
    path "population_index_lookup.tsv", emit: population_index_lookup
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    Rscript ${projectDir}/bin/index_population_assignment.R \
        --population_map ${population_map} \
        --population_col population \
        --identifier_col specimen_name \
        --indexed_output population_map_indexed.tsv \
        --lookup_output population_index_lookup.tsv

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
