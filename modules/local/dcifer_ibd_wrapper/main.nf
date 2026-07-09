/*
 * STEP - DCIFER_IBD_WRAPPER
 * Run the Dcifer IBD wrapper script
 */

process DCIFER_IBD_WRAPPER {
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'plasmogenepi/plasmodiumdrugres-dcifer:1.0.0' :
        'plasmogenepi/plasmodiumdrugres-dcifer:1.0.0' }"

    input:
    path allele_table

    output:
    path "btwn_host_rel.tsv", emit: btwn_host_rel
    path "versions.yml", emit: versions

    script:
    """
    Rscript ${projectDir}/bin/PGEcore/scripts/dcifer_ibd_wrapper/dcifer_ibd_wrapper.R \\
        --allele_table ${allele_table} --threads ${task.cpus} \\
        --btwn_host_rel_output btwn_host_rel.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$( R --version | sed -n '1s/.*\\([0-9]\\+\\.[0-9]\\+\\.[0-9]\\+\\).*/\\1/p' )
        dcifer: \$( Rscript -e 'cat(as.character(packageVersion("dcifer")))' 2>/dev/null || echo 'N/A' )
    END_VERSIONS
    """
}
