/*
 * STEP - EXTRACT_ALLELE_TABLE
 * Extract allele table from PMO file given a bioinformatics ID
 */

process EXTRACT_ALLELE_TABLE {
    tag "${pmo.name}"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
?         'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/48/486b002855a25cd4739d4f3da8f069b03c157e7a91c95b02bba56cf20438d202/data'
:         'community.wave.seqera.io/library/pmotools:b396e7b3d4cedca6' }"

    input:
    path pmo
    val replicate_libraries

    output:
    path "allele_table.tsv" , emit: allele_table
    path "versions.yml"     , emit: versions

    when:
    task.ext.when == null || task.ext.when

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
        pmotools-python: \$( pmotools-python --version | sed 's/^pmotools-python //' )
    END_VERSIONS
    """
}
