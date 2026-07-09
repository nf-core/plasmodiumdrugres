/*
 * STEP - EXTRACT_PANEL_INFO_TO_BED
 * Extract panel information to bed file, optionally including ref seqs
 */

process EXTRACT_PANEL_INFO_TO_BED {
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'plasmogenepi/plasmodiumdrugres-pmotools:1.0.0' :
        'plasmogenepi/plasmodiumdrugres-pmotools:1.0.0' }"

    input:
    path pmo
    val add_ref_seqs

    output:
    path "panel_info.bed", emit: panel_info_bed
    path "versions.yml", emit: versions

    script:
    def parameter_string = add_ref_seqs == "TRUE"
        ? "--add_ref_seqs"
        : ""
    """
    pmotools-python extract_insert_of_panels \\
        --file ${pmo} \\
        --output panel_info.bed \\
        ${parameter_string}

    # Rename header column from target_id to target_name
    awk 'BEGIN{FS=OFS="\t"} NR==1 {for(i=1;i<=NF;i++) if(\$i=="target_id") \$i="target_name"} {print}' \\
        panel_info.bed > panel_info.bed.tmp && \\
    mv panel_info.bed.tmp panel_info.bed

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        pmotools-python: \$( pmotools-python --version 2>/dev/null || echo 'N/A' )
    END_VERSIONS
    """
}
