/*
 * STEP - INDEX_POPULATION_ASSIGNMENT
 * Add stable internal indices to population assignment labels
 */

process INDEX_POPULATION_ASSIGNMENT {

    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
?         'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/25/25ec37d72caff047524cad028f190afbd7e97ff61cba29d8172883993c8a5c75/data'
:         'community.wave.seqera.io/library/r_tidyverse:4e1e0dec2f11d009' }"

    input:
    path population_map

    output:
    path "population_map_indexed.tsv", emit: population_map_indexed
    path "population_index_lookup.tsv", emit: population_index_lookup
    path "versions.yml", emit: versions

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
    END_VERSIONS
    """
}
