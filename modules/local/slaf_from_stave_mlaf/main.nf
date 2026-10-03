/*
 * STEP - SLAF_FROM_STAVE_MLAF
 * Compute single locus allele frequency (SLAF) from multi-locus AF (MLAF)
 */

process SLAF_FROM_STAVE_MLAF {

    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
?         'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/59/59694b9b3a63712c65ca417044bd5fb4d3927d9958fcf033bfa528a64d04caf8/data'
:         'community.wave.seqera.io/library/slaf_from_stave_mlaf:4c32c036540c052e' }"

    input:
    tuple val(mlaf_base), path(mlaf_input)

    output:
    tuple val("${mlaf_input.getBaseName(3)}"), path("${mlaf_input.getBaseName(3)}.aa_sl_from_ml.tsv"), emit: slaf
    path "versions.yml", emit: versions

    script:
    """
    export PATH="\$(Rscript -e 'cat(system.file(\"exec\", package = \"PGEcore\"))'):\${PATH}"
    slaf_from_stave_mlaf \\
        --mlaf ${mlaf_input} \\
        --output "${mlaf_input.getBaseName(3)}.aa_sl_from_ml.tsv"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$( R --version | sed -n '1s/.*\\([0-9]\\+\\.[0-9]\\+\\.[0-9]\\+\\).*/\\1/p' )
        r-pgecore: \$( Rscript -e 'cat(as.character(packageVersion("PGEcore")))' )
        variantstring: \$( Rscript -e 'cat(as.character(packageVersion("variantstring")))' 2>/dev/null || echo 'N/A' )
    END_VERSIONS
    """
}
