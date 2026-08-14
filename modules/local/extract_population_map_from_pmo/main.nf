/*
 * STEP - EXTRACT_POPULATION_MAP_FROM_PMO
 * Extract population map from PMO file
 */

process EXTRACT_POPULATION_MAP_FROM_PMO {

    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
?         'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/18/189c44118da9b46a927fb57c5ca01460fb93bfbc4b85bcb4484036888b8d5878/data'
:         'community.wave.seqera.io/library/pmotools:95ef48ca9c18fa35' }"

    input:
    path pmo
    val population_fields
    val separator

    output:
    path "population_map.tsv", emit: population_map
    path "versions.yml", emit: versions

    script:
    """
    pmotools-python export_specimen_meta_table \
        --file ${pmo} \
        --output specimen_meta_table.tsv

    python3 ${projectDir}/bin/specimen_info_to_population_map.py \
        --specimen-info specimen_meta_table.tsv \
        --output population_map.tsv \
        --fields ${population_fields} \
        --separator ${separator}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        pmotools-python: \$( pmotools-python --version 2>/dev/null || echo 'N/A' )
    END_VERSIONS
    """
}
