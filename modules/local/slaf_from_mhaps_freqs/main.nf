/*
 * STEP - SLAF_FROM_MHAPS_FREQS
 * Run the script that calculates single loci allele frequencies by utilizing the allele frequency of microhaplotypes that they are covered by
 */

process SLAF_FROM_MHAPS_FREQS {

    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
?         'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/7b/7b7ca5eb26f1bbaf3fba4ea585e789071aa49902df3182030df649f596ac97b1/data'
:         'community.wave.seqera.io/library/pgecore:e9024a6dc6e9a694' }"

    input:
    tuple val(group_name), path(mhaps_slaf_fnp)
    path loci_of_interest_per_microhaps_fnp

    output:
    tuple val("${group_name}"), path("${group_name}.slaf.tsv"), emit: slaf
    path "versions.yml", emit: versions

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
