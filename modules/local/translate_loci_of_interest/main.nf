/*
 * STEP - TRANSLATE_LOCI_OF_INTEREST
 * Pull out and translate loci of interest to amino acid calls
 */

process TRANSLATE_LOCI_OF_INTEREST {
    tag "${allele_table.name}"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
?         'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/68/6897d6ff9d3d1e9bc0f10f0ceb02a170773f32118f76e720048931bc85eea558/data'
:         'community.wave.seqera.io/library/translate_loci_of_interest:5289b509dbf0e57a' }"

    input:
    path allele_table
    path ref_bed
    path loci_of_interest

    output:
    path ("translated_loci/collapsed_amino_acid_calls.tsv.gz")               , emit: collapsed_amino_acid_calls
    path ("translated_loci/amino_acid_calls.tsv.gz")                         , emit: amino_acid_calls
    path ("translated_loci/loci_covered_by_target_samples_info.tsv")         , emit: loci_covered_by_target_samples_info
    path ("translated_loci/loci_of_interest_for_target_for_microhap.tsv.gz") , emit: loci_of_interest_for_target_for_microhap
    path "versions.yml"                                                      , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    export PATH="\$(Rscript -e 'cat(system.file(\"exec\", package = \"PGEcore\"))'):\${PATH}"
    translate_loci_of_interest \\
        --allele_table ${allele_table} \\
        --ref_bed ${ref_bed} \\
        --loci_of_interest ${loci_of_interest} \\
        --output_dir translated_loci \\
        ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        r-base: \$( R --version | sed -n '1s/.*\\([0-9]\\+\\.[0-9]\\+\\.[0-9]\\+\\).*/\\1/p' )
        r-pgecore: \$( Rscript -e 'cat(as.character(packageVersion("PGEcore")))' )
        bioconductor-biostrings: \$( Rscript -e 'cat(as.character(packageVersion("Biostrings")))' )
        bioconductor-pwalign: \$( Rscript -e 'cat(as.character(packageVersion("pwalign")))' )
    END_VERSIONS
    """
}
