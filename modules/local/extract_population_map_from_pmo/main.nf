/*
 * STEP - EXTRACT_POPULATION_MAP_FROM_PMO
 * Extract population map from PMO file
 */

process EXTRACT_POPULATION_MAP_FROM_PMO {
    tag "${pmo.name}"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
?         'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/48/486b002855a25cd4739d4f3da8f069b03c157e7a91c95b02bba56cf20438d202/data'
:         'community.wave.seqera.io/library/pmotools:b396e7b3d4cedca6' }"

    input:
    path pmo
    val population_fields
    val separator

    output:
    path "population_map.tsv" , emit: population_map
    path "versions.yml"       , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    pmotools-python export_specimen_meta_table \
        --file ${pmo} \
        --output specimen_meta_table.tsv

    specimen_info_to_population_map.py \
        --specimen-info specimen_meta_table.tsv \
        --output population_map.tsv \
        --fields ${population_fields} \
        --separator ${separator}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        pmotools-python: \$( pmotools-python --version | sed 's/^pmotools-python //' )
    END_VERSIONS
    """
}
