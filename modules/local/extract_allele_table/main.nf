/*
 * STEP - EXTRACT_ALLELE_TABLE
 * Extract allele table from PMO file given a bioinformatics ID
 */

process EXTRACT_ALLELE_TABLE {

    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
?         'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/18/189c44118da9b46a927fb57c5ca01460fb93bfbc4b85bcb4484036888b8d5878/data'
:         'community.wave.seqera.io/library/pmotools:49e8a88de6f47183' }"

    input:
    path pmo
    val replicate_libraries

    output:
    path "allele_table.tsv", emit: allele_table
    path "versions.yml", emit: versions

    script:
    """
    pmotools-python extract_allele_table \
        --file ${pmo} \
        --microhap_fields "reads" \
        --default_base_col_names library_sample_name,target_name,seq \
        --specimen_info_meta_fields specimen_name \
        --output pmo_allele_table.tsv

    python3 ${projectDir}/bin/pmo_allele_table_to_specimens.py \
        --input pmo_allele_table.tsv \
        --method ${replicate_libraries} \
        --output allele_table.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        pmotools-python: \$( pmotools-python --version 2>/dev/null || echo 'N/A' )
    END_VERSIONS
    """
}
