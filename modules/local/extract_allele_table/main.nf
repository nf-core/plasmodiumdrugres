/*
 * STEP - EXTRACT_ALLELE_TABLE
 * Extract allele table from PMO file given a bioinformatics ID
 */

process EXTRACT_ALLELE_TABLE {
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'plasmogenepi/plasmodiumdrugres-pmotools:1.0.0' :
        'plasmogenepi/plasmodiumdrugres-pmotools:1.0.0' }"

    input:
    path pmo

    output:
    path "allele_table.tsv", emit: allele_table
    path "versions.yml", emit: versions

    script:
    """
    pmotools-python extract_allele_table \\
        --file ${pmo} \\
        --representative_haps_fields "seq" \\
        --microhap_fields "reads" \\
        --default_base_col_names specimen_name,target_name,allele \\
        --output allele_table

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        pmotools-python: \$( pmotools-python --version 2>/dev/null || echo 'N/A' )
    END_VERSIONS
    """
}
