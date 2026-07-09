/*
 * STEP - FEM_WRAPPER
 * Run the FreqEstimationModel (FEM) wrapper script
 */

process FEM_WRAPPER {
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'plasmogenepi/plasmodiumdrugres-fem:1.0.0' :
        'plasmogenepi/plasmodiumdrugres-fem:1.0.0' }"

    input:
    path aa_calls
    path loci_group_table

    output:
    tuple val("${aa_calls.getBaseName(3)}"), path("${aa_calls.getBaseName(3)}.aa_mlaf.tsv"), emit: mlaf
    path "versions.yml", emit: versions

    script:
    """
    Rscript ${projectDir}/bin/PGEcore/scripts/FreqEstimationModel_wrapper/FreqEstimationModel_wrapper.R \\
        --aa_calls ${aa_calls} --groups ${loci_group_table} --coi 3 --mlaf_output "${aa_calls.getBaseName(3)}.aa_mlaf.tsv"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$( R --version | sed -n '1s/.*\\([0-9]\\+\\.[0-9]\\+\\.[0-9]\\+\\).*/\\1/p' )
        freqestimationmodel: \$( Rscript -e 'cat(as.character(packageVersion("FreqEstimationModel")))' 2>/dev/null || echo 'N/A' )
    END_VERSIONS
    """
}
