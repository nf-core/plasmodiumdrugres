/*
 * STEP - FEM_WRAPPER
 * Run the FreqEstimationModel (FEM) wrapper script
 */

// TODO: handle coi
process FEM_WRAPPER {

    tag "${aa_calls.name}"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
?         'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/62/6216ed31d33ddd6e9fc77859ecfb48f843df41a45482e840fe46837e9ef07623/data'
:         'community.wave.seqera.io/library/fem_wrapper:a701cba1416a0e6a' }"

    input:
    path aa_calls
    path loci_group_table

    output:
    tuple val("${aa_calls.getBaseName(3)}"), path("${aa_calls.getBaseName(3)}.aa_mlaf.tsv"), emit: mlaf
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    export PATH="\$(Rscript -e 'cat(system.file(\"exec\", package = \"PGEcore\"))'):\${PATH}"
    FreqEstimationModel_wrapper \\
        --aa_calls ${aa_calls} \\
        --loci_groups ${loci_group_table} \\
        --coi 3 \\
        --mlaf_output "${aa_calls.getBaseName(3)}.aa_mlaf.tsv"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$( R --version | sed -n '1s/.*\\([0-9]\\+\\.[0-9]\\+\\.[0-9]\\+\\).*/\\1/p' )
        r-pgecore: \$( Rscript -e 'cat(as.character(packageVersion("PGEcore")))' )
        freqestimationmodel: \$( Rscript -e 'cat(as.character(packageVersion("FreqEstimationModel")))' )
    END_VERSIONS
    """
}
