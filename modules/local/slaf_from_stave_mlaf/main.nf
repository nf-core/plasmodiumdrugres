/*
 * STEP - SLAF_FROM_STAVE_MLAF
 * Compute single locus allele frequency (SLAF) from multi-locus AF (MLAF)
 */

process SLAF_FROM_STAVE_MLAF {

    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
?         'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/81/81b920f9fbdfb306833b8fb40a0613cc6ab2ceb9ed5f185957da55b00e4d5281/data'
:         'community.wave.seqera.io/library/variantstring:baf88b1c56575a41' }"

    input:
    tuple val(mlaf_base), path(mlaf_input)

    output:
    tuple val("${mlaf_input.getBaseName(3)}"), path("${mlaf_input.getBaseName(3)}.aa_sl_from_ml.tsv"), emit: slaf
    path "versions.yml", emit: versions

    script:
    """
    Rscript ${projectDir}/bin/PGEcore/scripts/slaf_from_stave_mlaf/slaf_from_stave_mlaf.R \\
        --mlaf_input ${mlaf_input} --output "${mlaf_input.getBaseName(3)}.aa_sl_from_ml.tsv"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$( R --version | sed -n '1s/.*\\([0-9]\\+\\.[0-9]\\+\\.[0-9]\\+\\).*/\\1/p' )
        variantstring: \$( Rscript -e 'cat(as.character(packageVersion("variantstring")))' 2>/dev/null || echo 'N/A' )
    END_VERSIONS
    """
}
