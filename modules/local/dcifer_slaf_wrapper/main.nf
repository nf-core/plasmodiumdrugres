/*
 * STEP - DCIFER_SLAF_WRAPPER
 * Run the Dcifer allele frequency wrapper script
 */

process DCIFER_SLAF_WRAPPER {
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'plasmogenepi/plasmodiumdrugres-dcifer:1.0.0' :
        'plasmogenepi/plasmodiumdrugres-dcifer:1.0.0' }"

    input:
    path allele_table

    output:
    tuple val("${allele_table.getBaseName(3)}"), path("${allele_table.getBaseName(3)}.mhaps_slaf.tsv"), emit: mhaps_slaf
    path "versions.yml", emit: versions

    script:
    def extra_args = task.ext.args ? task.ext.args : ''
    """
    Rscript ${projectDir}/bin/PGEcore/scripts/dcifer_slaf_wrapper/dcifer_slaf_wrapper.R \\
        --allele_table ${allele_table} \\
        --slaf_output "${allele_table.getBaseName(3)}.mhaps_slaf.tsv" \\
        ${extra_args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$( R --version | sed -n '1s/.*\\([0-9]\\+\\.[0-9]\\+\\.[0-9]\\+\\).*/\\1/p' )
        dcifer: \$( Rscript -e 'cat(as.character(packageVersion("dcifer")))' 2>/dev/null || echo 'N/A' )
    END_VERSIONS
    """
}
