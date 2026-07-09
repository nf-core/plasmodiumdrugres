/*
 * STEP - COUNT_SAMPLES_BY_COI
 * Count the number of samples with each COI in the distribution
 */

process COUNT_SAMPLES_BY_COI {
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'plasmogenepi/plasmodiumdrugres-r-tidyverse:1.0.0' :
        'plasmogenepi/plasmodiumdrugres-r-tidyverse:1.0.0' }"

    input:
    path coi_calls

    output:
    path "sample_count_per_coi.tsv", emit: sample_count_per_coi
    path "versions.yml", emit: versions

    script:
    """
    Rscript ${projectDir}/bin/PGEcore/scripts/count_samples_by_coi/count_samples_by_coi.R \\
        --coi_calls ${coi_calls} \\
        --output sample_count_per_coi.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$( R --version | sed -n '1s/.*\\([0-9]\\+\\.[0-9]\\+\\.[0-9]\\+\\).*/\\1/p' )
    END_VERSIONS
    """
}
