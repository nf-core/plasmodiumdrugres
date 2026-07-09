/*
 * STEP - EXTRACT_POPULATION_MAP_FROM_PMO
 * Extract population map from PMO file
 */

process EXTRACT_POPULATION_MAP_FROM_PMO {
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'plasmogenepi/plasmodiumdrugres-pmotools:1.0.0' :
        'plasmogenepi/plasmodiumdrugres-pmotools:1.0.0' }"

    input:
    path pmo
    val population_fields
    val separator

    output:
    path "population_map.tsv", emit: population_map
    path "versions.yml", emit: versions

    script:
    """
    pmotools-python export_specimen_meta_table \\
        --file ${pmo} \\
        --output specimen_meta_table.tsv

    python3 ${projectDir}/bin/specimen_info_to_population_map.py \\
        --specimen-info specimen_meta_table.tsv \\
        --output population_map.tsv \\
        --fields ${population_fields} \\
        --separator ${separator}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        pmotools-python: \$( pmotools-python --version 2>/dev/null || echo 'N/A' )
    END_VERSIONS
    """
}
