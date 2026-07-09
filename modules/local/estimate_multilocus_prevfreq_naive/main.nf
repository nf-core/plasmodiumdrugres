/*
 * STEP - ESTIMATE_ML_PREVFREQ_NAIVE
 * Estimate multilocus prev/freq naively
 */

process ESTIMATE_ML_PREVFREQ_NAIVE {
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'plasmogenepi/plasmodiumdrugres-pgecore-r:1.0.0' :
        'plasmogenepi/plasmodiumdrugres-pgecore-r:1.0.0' }"

    input:
    path aa_calls
    path loci_groups
    val method

    output:
    tuple val("${aa_calls.getBaseName(3)}"), path("${aa_calls.getBaseName(3)}.aa_mlaf.tsv"), emit: mlaf
    tuple val("${aa_calls.getBaseName(3)}"), path("${aa_calls.getBaseName(3)}.aa_sl_from_ml.tsv"), emit: slaf_from_mlaf
    path "versions.yml", emit: versions

    script:
    def extra_args = task.ext.args ? task.ext.args : ''
    """
    Rscript ${projectDir}/bin/PGEcore/scripts/multilocus_prevfreq_naive/multilocus_prevfreq_naive.R \\
        --aa_table ${aa_calls} \\
        --loci_groups_input ${loci_groups} \\
        --output_path "${aa_calls.getBaseName(3)}.aa_mlaf.tsv" \\
        --recalc_single_locus_output_path "${aa_calls.getBaseName(3)}.aa_sl_from_ml.tsv" \\
        --method ${method} \\
        ${extra_args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$( R --version | sed -n '1s/.*\\([0-9]\\+\\.[0-9]\\+\\.[0-9]\\+\\).*/\\1/p' )
    END_VERSIONS
    """
}
