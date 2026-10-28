/*
 * STEP - SLAF_FROM_STAVE_MLAF
 * Compute single locus allele frequency (SLAF) from multi-locus AF (MLAF)
 */

process SLAF_FROM_STAVE_MLAF {
    tag "${mlaf_base}"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
?         'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/f0/f073209823f3bf084792041071652ee30ccee39a1e66196e3ef7700ee069416c/data'
:         'community.wave.seqera.io/library/slaf_from_stave_mlaf:409e9faea8baa13f' }"

    input:
    tuple val(mlaf_base), path(mlaf_input)

    output:
    tuple val("${mlaf_input.getBaseName(3)}"), path("${mlaf_input.getBaseName(3)}.aa_sl_from_ml.tsv") , emit: slaf
    path "versions.yml"                                                                               , emit: versions

    when:
    task.ext.when == null || task.ext.when

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
        variantstring: \$( Rscript -e 'cat(as.character(packageVersion("variantstring")))' )
    END_VERSIONS
    """
}
