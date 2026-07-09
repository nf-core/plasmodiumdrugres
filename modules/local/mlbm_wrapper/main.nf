/*
 * STEP - MLBM_WRAPPER
 * Run the MultiLociBiallelicModel (MLBM) wrapper script
 */

process MLBM_WRAPPER {
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'plasmogenepi/plasmodiumdrugres-variantstring:1.0.0' :
        'plasmogenepi/plasmodiumdrugres-variantstring:1.0.0' }"

    input:
    path aa_calls
    path loci_group_table

    output:
    tuple val("${aa_calls.getBaseName(3)}"), path("${aa_calls.getBaseName(3)}.aa_mlaf.tsv"), emit: mlaf
    path "versions.yml", emit: versions

    script:
    def extra_args = task.ext.args ? task.ext.args : ''
    """
    Rscript ${projectDir}/bin/PGEcore/scripts/MultiLociBiallelicModel_wrapper/MultiLociBiallelicModel_wrapper.R \\
        --aa_calls ${aa_calls} \\
        --loci_group_table ${loci_group_table} \\
        --mlaf_output "${aa_calls.getBaseName(3)}.aa_mlaf.tsv" \\
        ${extra_args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$( R --version | sed -n '1s/.*\\([0-9]\\+\\.[0-9]\\+\\.[0-9]\\+\\).*/\\1/p' )
        variantstring: \$( Rscript -e 'cat(as.character(packageVersion("variantstring")))' 2>/dev/null || echo 'N/A' )
    END_VERSIONS
    """
}
