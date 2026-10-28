/*
 * STEP - DCIFER_WRAPPER
 * Run the Dcifer allele frequency wrapper script
 */

process DCIFER_SLAF_WRAPPER {
    tag "${allele_table.name}"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
?         'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/22/226cddb1a4a0b5390d15f097f3281b4b4e4c5a47333083faf4df1c210a665279/data'
:         'community.wave.seqera.io/library/dcifer_slaf_wrapper:7f4ead3962e3451b' }"

    input:
    path allele_table

    output:
    tuple val("${allele_table.getBaseName(3)}"), path("${allele_table.getBaseName(3)}.mhaps_slaf.tsv") , emit: mhaps_slaf
    path "versions.yml"                                                                                , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def extra_args = task.ext.args ? task.ext.args : ''

    """
    export PATH="\$(Rscript -e 'cat(system.file(\"exec\", package = \"PGEcore\"))'):\${PATH}"
    dcifer_slaf_wrapper \\
        --allele_table ${allele_table} \\
        --slaf_output "${allele_table.getBaseName(3)}.mhaps_slaf.tsv" \\
        ${extra_args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$( R --version | sed -n '1s/.*\\([0-9]\\+\\.[0-9]\\+\\.[0-9]\\+\\).*/\\1/p' )
        r-pgecore: \$( Rscript -e 'cat(as.character(packageVersion("PGEcore")))' )
        dcifer: \$( Rscript -e 'cat(as.character(packageVersion("dcifer")))' )
    END_VERSIONS
    """
}
