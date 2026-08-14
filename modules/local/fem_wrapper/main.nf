/*
 * STEP - FEM_WRAPPER
 * Run the FreqEstimationModel (FEM) wrapper script
 */

// TODO: handle coi
process FEM_WRAPPER {

    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
?         'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/80/80a01e74c5e39ae20dfe8bfd9d0e1096372cd489febd1efc85f902f9ee880949/data'
:         'community.wave.seqera.io/library/fem_wrapper:c76f649ce875f71b' }"

    input:
    path aa_calls
    path loci_group_table

    output:
    tuple val("${aa_calls.getBaseName(3)}"), path("${aa_calls.getBaseName(3)}.aa_mlaf.tsv"), emit: mlaf
    path "versions.yml", emit: versions

    script:
    """
    Rscript ${projectDir}/bin/PGEcore/scripts/FreqEstimationModel_wrapper/FreqEstimationModel_wrapper.R \\
        --aa_calls ${aa_calls} --groups ${loci_group_table}  --coi 3 --mlaf_output "${aa_calls.getBaseName(3)}.aa_mlaf.tsv"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$( R --version | sed -n '1s/.*\\([0-9]\\+\\.[0-9]\\+\\.[0-9]\\+\\).*/\\1/p' )
        freqestimationmodel: \$( Rscript -e 'cat(as.character(packageVersion("FreqEstimationModel")))' 2>/dev/null || echo 'N/A' )
    END_VERSIONS
    """
}
