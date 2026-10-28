/*
 * STEP - SLAF_FROM_MHAPS_FREQS
 * Run the script that calculates single loci allele frequencies by utilizing the allele frequency of microhaplotypes that they are covered by
 */

process SLAF_FROM_MHAPS_FREQS {
    tag "${group_name}"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
?         'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/8b/8bb7bd8a2b78f4d460b00f1df86ec9e05e68ae1cfb2132665575995df5404ce1/data'
:         'community.wave.seqera.io/library/pgecore:7027edf49864476b' }"

    input:
    tuple val(group_name), path(mhaps_slaf_fnp)
    path loci_of_interest_per_microhaps_fnp

    output:
    tuple val("${group_name}"), path("${group_name}.slaf.tsv") , emit: slaf
    path "versions.yml"                                        , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:

    """
    export PATH="\$(Rscript -e 'cat(system.file(\"exec\", package = \"PGEcore\"))'):\${PATH}"
    slaf_from_mhaps_freqs \\
        --mhaps_slaf ${mhaps_slaf_fnp} \\
        --loci_of_interest_per_microhaps ${loci_of_interest_per_microhaps_fnp} \\
        --slaf_output ${group_name}.slaf.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$( R --version | sed -n '1s/.*\\([0-9]\\+\\.[0-9]\\+\\.[0-9]\\+\\).*/\\1/p' )
        r-pgecore: \$( Rscript -e 'cat(as.character(packageVersion("PGEcore")))' )
    END_VERSIONS
    """
}
