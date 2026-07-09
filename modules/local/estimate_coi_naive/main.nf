/*
 * STEP - ESTIMATE_COI_NAIVE
 * Estimate COI naively by integer or quantile method
 */

process ESTIMATE_COI_NAIVE {
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'plasmogenepi/plasmodiumdrugres-pgecore-r:1.0.0' :
        'plasmogenepi/plasmodiumdrugres-pgecore-r:1.0.0' }"

    input:
    path allele_table
    val method
    val threshold

    output:
    path "coi_table.tsv", emit: coi_table
    path "versions.yml", emit: versions

    script:
    def parameter_string = method == "integer_method"
        ? "--integer_threshold $threshold"
        : "--quantile_threshold $threshold"

    if ((method == "integer_method") && (!(threshold instanceof Integer) || (threshold < 0))) {
        throw new IllegalArgumentException("Error: For 'integer_method', 'threshold' must be a positive integer. Provided value: ${threshold}.")
    } else if ((method == "quantile_method") && !(threshold >= 0.0 && threshold <= 1.0)) {
        throw new IllegalArgumentException("Error: For 'quantile_method', 'threshold' must be a Double between 0 and 1. Provided value: ${threshold}.")
    } else if (!(method in ["integer_method", "quantile_method"])) {
        throw new IllegalArgumentException("Error: 'method' must be either 'integer_method' or 'quantile_method'. Provided value: ${method}.")
    }

    """
    Rscript ${projectDir}/bin/PGEcore/scripts/estimate_coi_naive/estimate_coi_naive.R \\
        --input_path ${allele_table} \\
        --output_path coi_table.tsv \\
        --method ${method} ${parameter_string}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$( R --version | sed -n '1s/.*\\([0-9]\\+\\.[0-9]\\+\\.[0-9]\\+\\).*/\\1/p' )
    END_VERSIONS
    """
}
