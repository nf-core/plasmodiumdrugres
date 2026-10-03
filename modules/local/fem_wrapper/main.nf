/*
 * STEP - FEM_WRAPPER
 * Run the FreqEstimationModel (FEM) wrapper script
 */

process FEM_WRAPPER {

    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
?         'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/e7/e71d228e76032b27c6fe6a5cabf12b9e8988d15d66f9bbc4d92a53b884801760/data'
:         'community.wave.seqera.io/library/fem_wrapper:5fbe1aa4f80981ca' }"

    input:
    path aa_calls
    path loci_group_table

    output:
    tuple val("${aa_calls.getBaseName(3)}"), path("${aa_calls.getBaseName(3)}.aa_mlaf.tsv"), emit: mlaf
    path "versions.yml", emit: versions

    script:
    def extra_args = task.ext.args ? task.ext.args : ''

    """
    export PATH="\$(Rscript -e 'cat(system.file(\"exec\", package = \"PGEcore\"))'):\${PATH}"
    FreqEstimationModel_wrapper \\
        --aa_calls ${aa_calls} \\
        --loci_groups ${loci_group_table} \\
        --mlaf_output "${aa_calls.getBaseName(3)}.aa_mlaf.tsv" \\
        ${extra_args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$( R --version | sed -n '1s/.*\\([0-9]\\+\\.[0-9]\\+\\.[0-9]\\+\\).*/\\1/p' )
        r-pgecore: \$( Rscript -e 'cat(as.character(packageVersion("PGEcore")))' )
        freqestimationmodel: \$( Rscript -e 'cat(as.character(packageVersion("FreqEstimationModel")))' 2>/dev/null || echo 'N/A' )
    END_VERSIONS
    """
}
