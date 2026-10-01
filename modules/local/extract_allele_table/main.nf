/*
 * STEP - EXTRACT_ALLELE_TABLE
 * Extract allele table from PMO file given a bioinformatics ID
 */

process EXTRACT_ALLELE_TABLE {

    tag "${pmo.name}"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
?         'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/18/189c44118da9b46a927fb57c5ca01460fb93bfbc4b85bcb4484036888b8d5878/data'
:         'community.wave.seqera.io/library/pmotools:49e8a88de6f47183' }"

    input:
    path pmo

    output:
    path "allele_table.tsv", emit: allele_table
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    pmotools-python extract_allele_table \
        --file ${pmo} \
        --microhap_fields "reads" \
        --default_base_col_names specimen_name,target_name,seq \
        --output allele_table

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        pmotools-python: \$( pmotools-python --version | sed 's/^pmotools-python //' )
    END_VERSIONS
    """
}
